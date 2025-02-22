use full_palette::GREY;
use plotters::prelude::*;
use rand::prelude::*;
use rand_distr::{Distribution, Normal};
use rayon::prelude::*;
use rustler::types::binary::Binary;
use rustler::{Error as RustlerError, NifStruct};
use std::cmp;
use std::cmp::Ordering;
use std::cmp::Reverse;
use std::collections::BinaryHeap;
use std::error::Error;
use std::f32::consts::PI;
use std::io::Read;

pub trait Validatable
where
    Self: Sized,
{
    fn validate(&self) -> Result<(), RustlerError>;
}

#[derive(Clone, Debug, Default, NifStruct)]
#[module = "LiveCheck.Scheduler.GreedyConfig"]
pub struct GreedyConfig {
    pub interval: u32,
    pub mean_runtime: f64,
    pub runtime_variance: f64,
    pub constraints: Vec<SchedulerConstraint>,
    pub schedule_window: u32,
    pub schedule_start: u32,
    pub schedule_end: u32,
}

#[derive(Clone, Debug, Default, NifStruct)]
#[module = "LiveCheck.Scheduler.BalancedConfig"]
pub struct BalancedConfig {
    // Algo-specific Parameters
    pub pool_size: usize,
    pub schedule_start: u32,
    pub schedule_end: u32,
    pub reschedule_range: u32,
    pub constraints: Vec<SchedulerConstraint>,
    // Genetic Algorithm Parameters
    pub pop_size: usize,
    pub elitism_size: usize,
    pub selection_size: usize,
    pub mutation_rate: f64,
    pub max_generations: usize,
    pub max_good_runs: usize,
    // Jitter Parameters
    pub jitter_mean: f64,
    pub jitter_std_dev: f64,
}

#[derive(Clone, Debug, Default, NifStruct)]
#[module = "LiveCheck.Scheduler.Constraint"]
pub struct SchedulerConstraint {
    pub interval: u32,
    pub start_time: u32,
    pub mean_runtime: f64,
    pub runtime_variance: f64,
}

#[derive(Clone, Debug, Default)]
pub struct Schedule {
    pub genes: Vec<Task>,
    pub fitness: f64,
}

#[derive(Clone, Debug, Default, NifStruct)]
#[module = "LiveCheck.Scheduler.Task"]
pub struct Task {
    pub run: u32,
    pub start: u32,
    pub runtime: u32,
    pub blocking_time: u32,
}

impl Validatable for GreedyConfig {
    fn validate(&self) -> Result<(), RustlerError> {
        if self.constraints.is_empty() {
            return Err(RustlerError::Atom("empty_constraints"));
        }

        if self.schedule_end == 0 {
            return Err(RustlerError::Atom("invalid_schedule_end"));
        }

        if self.interval == 0 {
            return Err(RustlerError::Atom("invalid_interval"));
        }

        if self.schedule_start >= self.schedule_end {
            return Err(RustlerError::Atom("invalid_schedule_range"));
        }

        Ok(())
    }
}

impl Validatable for BalancedConfig {
    fn validate(&self) -> Result<(), RustlerError> {
        if self.constraints.is_empty() {
            return Err(RustlerError::Atom("empty_constraints"));
        }

        if self.schedule_end == 0 {
            return Err(RustlerError::Atom("invalid_schedule_end"));
        }

        if self.schedule_start >= self.schedule_end {
            return Err(RustlerError::Atom("invalid_schedule_range"));
        }

        if self.pool_size == 0 {
            return Err(RustlerError::Atom("invalid_pool_size"));
        }

        if self.pop_size == 0 {
            return Err(RustlerError::Atom("invalid_pop_size"));
        }

        if self.elitism_size == 0 {
            return Err(RustlerError::Atom("invalid_elitism_size"));
        }

        if self.selection_size == 0 {
            return Err(RustlerError::Atom("invalid_selection_size"));
        }

        if self.mutation_rate < 0.0 || self.mutation_rate > 1.0 {
            return Err(RustlerError::Atom("invalid_mutation_rate"));
        }

        if self.selection_size > self.pop_size {
            return Err(RustlerError::Atom("selection_size_larger_than_pop"));
        }

        Ok(())
    }
}

impl Schedule {
    fn new(config: &BalancedConfig) -> Self {
        let mut rng = thread_rng();
        let mut genes = Vec::with_capacity(config.constraints.len());
        let jitter = Normal::new(config.jitter_mean, config.jitter_std_dev).unwrap();

        for (i, constraint) in config.constraints.iter().enumerate() {
            let runtime = Normal::new(constraint.mean_runtime, constraint.runtime_variance)
                .unwrap()
                .sample(&mut rng)
                .trunc() as u32;
            let offset = jitter.sample(&mut rng).trunc() as i32;
            let schedule = (constraint.start_time.saturating_add_signed(offset))
                .clamp(
                    constraint
                        .start_time
                        .saturating_add_signed(-(config.reschedule_range as i32)),
                    constraint
                        .start_time
                        .saturating_add_signed(config.reschedule_range as i32),
                )
                .clamp(config.schedule_start, config.schedule_end);

            genes.push(Task {
                run: i as u32,
                start: schedule,
                runtime: runtime,
                ..Default::default()
            });
        }

        Self {
            genes,
            ..Default::default()
        }
    }

    fn fitness(&mut self, config: &BalancedConfig) {
        let mut worker_pool: BinaryHeap<Reverse<u32>> = BinaryHeap::with_capacity(config.pool_size);
        let mut max_blocking_time = 0;

        self.genes.sort_unstable_by_key(|k| k.start);

        let &Task { run: a, .. } = self.genes.first().unwrap();
        let &Task { run: b, .. } = self.genes.last().unwrap();

        let schedule_min = config.constraints[a as usize].start_time;
        let schedule_max = config.constraints[b as usize].start_time;

        let mut deviation = 0;

        for _ in 0..config.pool_size {
            worker_pool.push(Reverse(0));
        }

        for schedule in self.genes.iter_mut() {
            let Reverse(soonest_end_time) = worker_pool.pop().unwrap();

            if soonest_end_time > schedule.start {
                schedule.blocking_time = soonest_end_time - schedule.start;
                max_blocking_time = max_blocking_time.max(schedule.blocking_time);
            } else {
                schedule.blocking_time = 0;
            }

            worker_pool.push(Reverse(soonest_end_time + schedule.runtime));

            deviation += u64::pow(
                schedule.start as u64 - config.constraints[schedule.run as usize].start_time as u64,
                2,
            );
        }

        let utilization = match max_blocking_time {
            0 => 1.0,
            t => 1.0 / t as f64,
        };

        let normalized_deviation = (deviation as f64 / config.constraints.len() as f64).sqrt()
            / (schedule_max - schedule_min) as f64;

        self.fitness = utilization * (1.0 - normalized_deviation);
        self.genes.sort_unstable_by_key(|k| k.run);
    }

    fn mutate(&mut self, config: &BalancedConfig) {
        let mut rng = thread_rng();
        let jitter = Normal::new(config.jitter_mean, config.jitter_std_dev).unwrap();

        for schedule in self.genes.iter_mut() {
            if rng.gen_bool(config.mutation_rate) {
                let constraint = &config.constraints[schedule.run as usize];
                let offset = jitter.sample(&mut rng).trunc() as i32;
                let start = (schedule.start.saturating_add_signed(offset))
                    .clamp(
                        constraint
                            .start_time
                            .saturating_add_signed(-(config.reschedule_range as i32)),
                        constraint
                            .start_time
                            .saturating_add_signed(config.reschedule_range as i32),
                    )
                    .clamp(config.schedule_start, config.schedule_end);

                schedule.start = start;
            }
        }
    }
}

fn generate_population(config: &BalancedConfig) -> Vec<Schedule> {
    (0..config.pop_size)
        .into_par_iter()
        .map(|_| Schedule::new(config))
        .collect()
}

fn mutate(mut population: Vec<Schedule>, config: &BalancedConfig) -> Vec<Schedule> {
    population
        .par_iter_mut()
        .for_each(|chromosome| chromosome.mutate(config));
    population
}

fn evaluate(mut population: Vec<Schedule>, config: &BalancedConfig) -> Vec<Schedule> {
    population
        .par_iter_mut()
        .for_each(|chromosome| chromosome.fitness(config));
    population
        .sort_unstable_by(|a, b| b.fitness.partial_cmp(&a.fitness).unwrap_or(Ordering::Equal));
    population
}

fn crossover(chromosomes: &[Schedule]) -> Vec<Schedule> {
    chromosomes
        .par_chunks_exact(2)
        .flat_map(|pair| {
            let (p1, p2) = (&pair[0], &pair[1]);
            let (c1, c2) = perform_two_point_crossover(p1, p2);
            vec![c1, c2]
        })
        .collect()
}

fn perform_single_point_crossover(p_1: &Schedule, p_2: &Schedule) -> (Schedule, Schedule) {
    let m = thread_rng().gen_range(0..p_1.genes.len());
    let mut genes_1 = Vec::with_capacity(p_1.genes.len());
    let mut genes_2 = Vec::with_capacity(p_1.genes.len());

    genes_1.extend_from_slice(&p_1.genes[..m]);
    genes_2.extend_from_slice(&p_2.genes[..m]);
    genes_1.extend_from_slice(&p_2.genes[m..]);
    genes_2.extend_from_slice(&p_1.genes[m..]);

    (
        Schedule {
            genes: genes_1,
            ..Default::default()
        },
        Schedule {
            genes: genes_2,
            ..Default::default()
        },
    )
}

fn perform_two_point_crossover(p_1: &Schedule, p_2: &Schedule) -> (Schedule, Schedule) {
    let mut rng = thread_rng();
    let m_1 = rng.gen_range(0..p_1.genes.len());
    let m_2 = rng.gen_range(m_1..p_1.genes.len());
    let mut genes_1 = Vec::with_capacity(p_1.genes.len());
    let mut genes_2 = Vec::with_capacity(p_1.genes.len());

    genes_1.extend_from_slice(&p_1.genes[..m_1]);
    genes_2.extend_from_slice(&p_2.genes[..m_1]);
    genes_1.extend_from_slice(&p_2.genes[m_1..m_2]);
    genes_2.extend_from_slice(&p_1.genes[m_1..m_2]);
    genes_1.extend_from_slice(&p_1.genes[m_2..]);
    genes_2.extend_from_slice(&p_2.genes[m_2..]);

    (
        Schedule {
            genes: genes_1,
            ..Default::default()
        },
        Schedule {
            genes: genes_2,
            ..Default::default()
        },
    )
}

fn natural_selection(chromosomes: &[Schedule], n: usize) -> Vec<Schedule> {
    chromosomes[..std::cmp::min(n, chromosomes.len())].to_vec()
}

fn elitism(chromosomes: &[Schedule], n: usize) -> Vec<Schedule> {
    chromosomes[..std::cmp::min(n, chromosomes.len())].to_vec()
}

fn evolve(
    mut population: Vec<Schedule>,
    config: &BalancedConfig,
    mut terminate: impl FnMut(&[Schedule], usize) -> bool,
) -> Vec<Schedule> {
    let mut generation = 0;

    loop {
        population = evaluate(population, config);
        if terminate(&population, generation) {
            break;
        }

        let selected = natural_selection(&population, config.selection_size);
        let elites = elitism(&population, config.elitism_size);
        let children = crossover(&selected);

        population = elites;
        population.extend(mutate(children, config));

        generation += 1;
    }

    population
}

#[rustler::nif(schedule = "DirtyCpu")]
fn greedy_schedule(config: GreedyConfig) -> Result<u32, RustlerError> {
    if let Err(err) = config.validate() {
        return Err(err);
    }

    let mut rng = thread_rng();
    let runtime = Normal::new(config.mean_runtime, config.runtime_variance)
        .unwrap()
        .sample(&mut rng)
        .trunc() as u32;

    let mut contention: Vec<u32> = vec![0; config.schedule_window as usize];

    for &SchedulerConstraint {
        interval,
        start_time,
        mean_runtime,
        runtime_variance,
    } in config.constraints.iter()
    {
        let runtime = Normal::new(mean_runtime, runtime_variance).unwrap();

        for i in 0..(config.schedule_window / interval) {
            let start = start_time + i * interval;
            let end = (start + runtime.sample(&mut rng).trunc() as u32).min(config.schedule_end);

            for j in start..end {
                contention[j as usize] += 1;
            }
        }
    }

    let mut minimal_contention = u32::MAX;
    let mut minimal_contention_start = config.schedule_start;

    for i in config.schedule_start..=config.schedule_end {
        let mut contention_sum = 0;

        for j in 0..cmp::min(config.schedule_window / config.interval, 4) {
            let start_index = i as usize + j as usize * config.interval as usize;
            let start_mod = start_index % contention.len();
            let end_mod = (start_index + runtime as usize) % contention.len();

            contention_sum += if start_mod > end_mod {
                contention[start_mod..(config.schedule_window as usize)]
                    .iter()
                    .sum::<u32>()
                    + contention[0..end_mod].iter().sum::<u32>()
            } else {
                contention[start_mod..end_mod].iter().sum::<u32>()
            };
        }

        if contention_sum < minimal_contention {
            minimal_contention = contention_sum;
            minimal_contention_start = i;
        }
    }

    Ok(minimal_contention_start)
}

#[rustler::nif(schedule = "DirtyCpu")]
fn balanced_schedule(config: BalancedConfig) -> Result<Vec<Task>, RustlerError> {
    if let Err(err) = config.validate() {
        return Err(err);
    }

    let population = generate_population(&config);
    let mut original = population.first().unwrap().clone();
    original.fitness(&config);

    visualize_schedule(&original.genes, "original.png").unwrap();

    let mut best_fitness = 0.0;
    let mut best_fitness_count = 0;

    let population = evolve(population, &config, |population, generation| -> bool {
        if let Some(best) = population.first() {
            if best_fitness < best.fitness {
                best_fitness = best.fitness;
                best_fitness_count = 0;
            } else {
                best_fitness_count += 1;
            }
        }

        generation == config.max_generations || best_fitness_count == config.max_good_runs
    });

    let genes = population.first().unwrap().genes.clone();

    visualize_schedule(&genes, "schedule.png").unwrap();

    Ok(genes)
}

fn visualize_schedule(schedule: &[Task], output_path: &str) -> Result<(), Box<dyn Error>> {
    // Create a drawing area for the chart.
    let root = BitMapBackend::new(output_path, (2000, 2000)).into_drawing_area();
    root.fill(&WHITE)?;

    let max_schedules = schedule.len();

    // Determine the range of backends and time.
    let max_time = schedule
        .iter()
        .map(|s| s.start + s.blocking_time + s.runtime)
        .max()
        .unwrap_or(0);

    // Define the chart area and margins.
    let mut chart = ChartBuilder::on(&root)
        .caption("Check Schedule", ("sans-serif", 30))
        .margin(10)
        .x_label_area_size(40)
        .y_label_area_size(40)
        .build_cartesian_2d(0..max_time, 0..max_schedules + 1)?;

    // Configure the chart's x and y labels.
    chart
        .configure_mesh()
        .disable_x_mesh()
        .disable_y_mesh()
        .x_desc("Time")
        .y_desc("Backend")
        .y_labels(max_schedules + 1)
        .x_labels(10)
        .draw()?;

    // Draw each job as a bar in the chart.
    for &Task {
        run,
        start,
        runtime,
        blocking_time,
        ..
    } in schedule.iter()
    {
        let color = Palette99::pick(run as usize).to_rgba();

        let bars = if blocking_time > 0 {
            vec![
                Rectangle::new(
                    [
                        (start, run as usize),
                        (start + blocking_time, run as usize + 1),
                    ],
                    GREY.filled(),
                ),
                Rectangle::new(
                    [
                        (start + blocking_time, run as usize),
                        (start + blocking_time + runtime, run as usize + 1),
                    ],
                    color.filled(),
                ),
            ]
        } else {
            vec![Rectangle::new(
                [(start, run as usize), (start + runtime, run as usize + 1)],
                color.filled(),
            )]
        };

        chart
            .draw_series(bars)?
            .label(format!("Run {}", run))
            .legend(move |(x, y)| Rectangle::new([(x, y - 5), (x + 10, y + 5)], color.filled()));
    }

    // Configure the legend for the chart.
    chart
        .configure_series_labels()
        .border_style(&BLACK)
        .draw()?;

    // Save the result to the specified output path.
    root.present()?;
    Ok(())
}

/// Encodes an RGBA image to a ThumbHash. RGB should not be premultiplied by A.
///
/// * `w`: The width of the input image. Must be ≤100px.
/// * `h`: The height of the input image. Must be ≤100px.
/// * `rgba`: The pixels in the input image, row-by-row. Must have `w*h*4` elements.
#[rustler::nif]
// pub fn rgba_to_thumb_hash(w: usize, h: usize, rgba: &[u8]) -> Vec<u8> {
pub fn rgba_to_thumb_hash(w: usize, h: usize, rgba: Binary) -> Vec<u8> {
    // Encoding an image larger than 100x100 is slow with no benefit
    assert!(w <= 100 && h <= 100);
    assert_eq!(rgba.len(), w * h * 4);

    // Determine the average color
    let mut avg_r = 0.0;
    let mut avg_g = 0.0;
    let mut avg_b = 0.0;
    let mut avg_a = 0.0;
    for rgba in rgba.chunks_exact(4) {
        let alpha = rgba[3] as f32 / 255.0;
        avg_r += alpha / 255.0 * rgba[0] as f32;
        avg_g += alpha / 255.0 * rgba[1] as f32;
        avg_b += alpha / 255.0 * rgba[2] as f32;
        avg_a += alpha;
    }
    if avg_a > 0.0 {
        avg_r /= avg_a;
        avg_g /= avg_a;
        avg_b /= avg_a;
    }

    let has_alpha = avg_a < (w * h) as f32;
    let l_limit = if has_alpha { 5 } else { 7 }; // Use fewer luminance bits if there's alpha
    let lx = (((l_limit * w) as f32 / w.max(h) as f32).round() as usize).max(1);
    let ly = (((l_limit * h) as f32 / w.max(h) as f32).round() as usize).max(1);
    let mut l = Vec::with_capacity(w * h); // luminance
    let mut p = Vec::with_capacity(w * h); // yellow - blue
    let mut q = Vec::with_capacity(w * h); // red - green
    let mut a = Vec::with_capacity(w * h); // alpha

    // Convert the image from RGBA to LPQA (composite atop the average color)
    for rgba in rgba.chunks_exact(4) {
        let alpha = rgba[3] as f32 / 255.0;
        let r = avg_r * (1.0 - alpha) + alpha / 255.0 * rgba[0] as f32;
        let g = avg_g * (1.0 - alpha) + alpha / 255.0 * rgba[1] as f32;
        let b = avg_b * (1.0 - alpha) + alpha / 255.0 * rgba[2] as f32;
        l.push((r + g + b) / 3.0);
        p.push((r + g) / 2.0 - b);
        q.push(r - g);
        a.push(alpha);
    }

    // Encode using the DCT into DC (constant) and normalized AC (varying) terms
    let encode_channel = |channel: &[f32], nx: usize, ny: usize| -> (f32, Vec<f32>, f32) {
        let mut dc = 0.0;
        let mut ac = Vec::with_capacity(nx * ny / 2);
        let mut scale = 0.0;
        let mut fx = [0.0].repeat(w);
        for cy in 0..ny {
            let mut cx = 0;
            while cx * ny < nx * (ny - cy) {
                let mut f = 0.0;
                for x in 0..w {
                    fx[x] = (PI / w as f32 * cx as f32 * (x as f32 + 0.5)).cos();
                }
                for y in 0..h {
                    let fy = (PI / h as f32 * cy as f32 * (y as f32 + 0.5)).cos();
                    for x in 0..w {
                        f += channel[x + y * w] * fx[x] * fy;
                    }
                }
                f /= (w * h) as f32;
                if cx > 0 || cy > 0 {
                    ac.push(f);
                    scale = f.abs().max(scale);
                } else {
                    dc = f;
                }
                cx += 1;
            }
        }
        if scale > 0.0 {
            for ac in &mut ac {
                *ac = 0.5 + 0.5 / scale * *ac;
            }
        }
        (dc, ac, scale)
    };
    let (l_dc, l_ac, l_scale) = encode_channel(&l, lx.max(3), ly.max(3));
    let (p_dc, p_ac, p_scale) = encode_channel(&p, 3, 3);
    let (q_dc, q_ac, q_scale) = encode_channel(&q, 3, 3);
    let (a_dc, a_ac, a_scale) = if has_alpha {
        encode_channel(&a, 5, 5)
    } else {
        (1.0, Vec::new(), 1.0)
    };

    // Write the constants
    let is_landscape = w > h;
    let header24 = (63.0 * l_dc).round() as u32
        | (((31.5 + 31.5 * p_dc).round() as u32) << 6)
        | (((31.5 + 31.5 * q_dc).round() as u32) << 12)
        | (((31.0 * l_scale).round() as u32) << 18)
        | if has_alpha { 1 << 23 } else { 0 };
    let header16 = (if is_landscape { ly } else { lx }) as u16
        | (((63.0 * p_scale).round() as u16) << 3)
        | (((63.0 * q_scale).round() as u16) << 9)
        | if is_landscape { 1 << 15 } else { 0 };
    let mut hash = Vec::with_capacity(25);
    hash.extend_from_slice(&[
        (header24 & 255) as u8,
        ((header24 >> 8) & 255) as u8,
        (header24 >> 16) as u8,
        (header16 & 255) as u8,
        (header16 >> 8) as u8,
    ]);
    let mut is_odd = false;
    if has_alpha {
        hash.push((15.0 * a_dc).round() as u8 | (((15.0 * a_scale).round() as u8) << 4));
    }

    // Write the varying factors
    for ac in [l_ac, p_ac, q_ac] {
        for f in ac {
            let u = (15.0 * f).round() as u8;
            if is_odd {
                *hash.last_mut().unwrap() |= u << 4;
            } else {
                hash.push(u);
            }
            is_odd = !is_odd;
        }
    }
    if has_alpha {
        for f in a_ac {
            let u = (15.0 * f).round() as u8;
            if is_odd {
                *hash.last_mut().unwrap() |= u << 4;
            } else {
                hash.push(u);
            }
            is_odd = !is_odd;
        }
    }
    hash
}

fn read_byte(bytes: &mut &[u8]) -> Result<u8, ()> {
    let mut byte = [0; 1];
    bytes.read_exact(&mut byte).map_err(|_| ())?;
    Ok(byte[0])
}

/// Decodes a ThumbHash to an RGBA image.
///
/// RGB is not be premultiplied by A. Returns the width, height, and pixels of
/// the rendered placeholder image. An error will be returned if the input is
/// too short.
#[rustler::nif]
pub fn thumb_hash_to_rgba(hash_bin: Vec<u8>) -> Result<(usize, usize, Vec<u8>), ()> {
    let mut hash = hash_bin.as_slice();
    let ratio = thumb_hash_to_approximate_aspect_ratio(hash)?;

    // Read the constants
    let header24 = read_byte(&mut hash)? as u32
        | ((read_byte(&mut hash)? as u32) << 8)
        | ((read_byte(&mut hash)? as u32) << 16);
    let header16 = read_byte(&mut hash)? as u16 | ((read_byte(&mut hash)? as u16) << 8);
    let l_dc = (header24 & 63) as f32 / 63.0;
    let p_dc = ((header24 >> 6) & 63) as f32 / 31.5 - 1.0;
    let q_dc = ((header24 >> 12) & 63) as f32 / 31.5 - 1.0;
    let l_scale = ((header24 >> 18) & 31) as f32 / 31.0;
    let has_alpha = (header24 >> 23) != 0;
    let p_scale = ((header16 >> 3) & 63) as f32 / 63.0;
    let q_scale = ((header16 >> 9) & 63) as f32 / 63.0;
    let is_landscape = (header16 >> 15) != 0;
    let l_max = if has_alpha { 5 } else { 7 };
    let lx = 3.max(if is_landscape { l_max } else { header16 & 7 }) as usize;
    let ly = 3.max(if is_landscape { header16 & 7 } else { l_max }) as usize;
    let (a_dc, a_scale) = if has_alpha {
        let header8 = read_byte(&mut hash)?;
        ((header8 & 15) as f32 / 15.0, (header8 >> 4) as f32 / 15.0)
    } else {
        (1.0, 1.0)
    };

    // Read the varying factors (boost saturation by 1.25x to compensate for quantization)
    let mut prev_bits = None;
    let mut decode_channel = |nx: usize, ny: usize, scale: f32| -> Result<Vec<f32>, ()> {
        let mut ac = Vec::with_capacity(nx * ny);
        for cy in 0..ny {
            let mut cx = if cy > 0 { 0 } else { 1 };
            while cx * ny < nx * (ny - cy) {
                let bits = if let Some(bits) = prev_bits {
                    prev_bits = None;
                    bits
                } else {
                    let bits = read_byte(&mut hash)?;
                    prev_bits = Some(bits >> 4);
                    bits & 15
                };
                ac.push((bits as f32 / 7.5 - 1.0) * scale);
                cx += 1;
            }
        }
        Ok(ac)
    };
    let l_ac = decode_channel(lx, ly, l_scale)?;
    let p_ac = decode_channel(3, 3, p_scale * 1.25)?;
    let q_ac = decode_channel(3, 3, q_scale * 1.25)?;
    let a_ac = if has_alpha {
        decode_channel(5, 5, a_scale)?
    } else {
        Vec::new()
    };

    // Decode using the DCT into RGB
    let (w, h) = if ratio > 1.0 {
        (32, (32.0 / ratio).round() as usize)
    } else {
        ((32.0 * ratio).round() as usize, 32)
    };
    let mut rgba = Vec::with_capacity(w * h * 4);
    let mut fx = [0.0].repeat(7);
    let mut fy = [0.0].repeat(7);
    for y in 0..h {
        for x in 0..w {
            let mut l = l_dc;
            let mut p = p_dc;
            let mut q = q_dc;
            let mut a = a_dc;

            // Precompute the coefficients
            for cx in 0..lx.max(if has_alpha { 5 } else { 3 }) {
                fx[cx] = (PI / w as f32 * (x as f32 + 0.5) * cx as f32).cos();
            }
            for cy in 0..ly.max(if has_alpha { 5 } else { 3 }) {
                fy[cy] = (PI / h as f32 * (y as f32 + 0.5) * cy as f32).cos();
            }

            // Decode L
            let mut j = 0;
            for cy in 0..ly {
                let mut cx = if cy > 0 { 0 } else { 1 };
                let fy2 = fy[cy] * 2.0;
                while cx * ly < lx * (ly - cy) {
                    l += l_ac[j] * fx[cx] * fy2;
                    j += 1;
                    cx += 1;
                }
            }

            // Decode P and Q
            let mut j = 0;
            for cy in 0..3 {
                let mut cx = if cy > 0 { 0 } else { 1 };
                let fy2 = fy[cy] * 2.0;
                while cx < 3 - cy {
                    let f = fx[cx] * fy2;
                    p += p_ac[j] * f;
                    q += q_ac[j] * f;
                    j += 1;
                    cx += 1;
                }
            }

            // Decode A
            if has_alpha {
                let mut j = 0;
                for cy in 0..5 {
                    let mut cx = if cy > 0 { 0 } else { 1 };
                    let fy2 = fy[cy] * 2.0;
                    while cx < 5 - cy {
                        a += a_ac[j] * fx[cx] * fy2;
                        j += 1;
                        cx += 1;
                    }
                }
            }

            // Convert to RGB
            let b = l - 2.0 / 3.0 * p;
            let r = (3.0 * l - b + q) / 2.0;
            let g = r - q;
            rgba.extend_from_slice(&[
                (r.clamp(0.0, 1.0) * 255.0) as u8,
                (g.clamp(0.0, 1.0) * 255.0) as u8,
                (b.clamp(0.0, 1.0) * 255.0) as u8,
                (a.clamp(0.0, 1.0) * 255.0) as u8,
            ]);
        }
    }
    Ok((w, h, rgba))
}

/// Extracts the average color from a ThumbHash.
///
/// Returns the RGBA values where each value ranges from 0 to 1. RGB is not be
/// premultiplied by A. An error will be returned if the input is too short.
pub fn thumb_hash_to_average_rgba(hash: &[u8]) -> Result<(f32, f32, f32, f32), ()> {
    if hash.len() < 5 {
        return Err(());
    }
    let header = hash[0] as u32 | ((hash[1] as u32) << 8) | ((hash[2] as u32) << 16);
    let l = (header & 63) as f32 / 63.0;
    let p = ((header >> 6) & 63) as f32 / 31.5 - 1.0;
    let q = ((header >> 12) & 63) as f32 / 31.5 - 1.0;
    let has_alpha = (header >> 23) != 0;
    let a = if has_alpha {
        (hash[5] & 15) as f32 / 15.0
    } else {
        1.0
    };
    let b = l - 2.0 / 3.0 * p;
    let r = (3.0 * l - b + q) / 2.0;
    let g = r - q;
    Ok((r.clamp(0.0, 1.0), g.clamp(0.0, 1.0), b.clamp(0.0, 1.0), a))
}

/// Extracts the approximate aspect ratio of the original image.
///
/// An error will be returned if the input is too short.
pub fn thumb_hash_to_approximate_aspect_ratio(hash: &[u8]) -> Result<f32, ()> {
    if hash.len() < 5 {
        return Err(());
    }
    let has_alpha = (hash[2] & 0x80) != 0;
    let l_max = if has_alpha { 5 } else { 7 };
    let l_min = hash[3] & 7;
    let is_landscape = (hash[4] & 0x80) != 0;
    let lx = if is_landscape { l_max } else { l_min };
    let ly = if is_landscape { l_min } else { l_max };
    Ok(lx as f32 / ly as f32)
}

rustler::init!("Elixir.LiveCheck.Native");
