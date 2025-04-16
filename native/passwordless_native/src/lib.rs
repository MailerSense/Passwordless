use markup_fmt::config::{LanguageOptions, LayoutOptions, LineBreak};
use markup_fmt::{config::FormatOptions, format_text as format_markup, Language};
use rustler::{Atom, Encoder, Env, NifResult, NifStruct, Term};
use std::borrow::Cow;
use std::borrow::Cow::Owned;
use std::collections::HashMap;
use std::path::Path;

use dprint_plugin_typescript::configuration::{
    ConfigurationBuilder, NextControlFlowPosition, QuoteStyle,
};
use dprint_plugin_typescript::format_text as format_typescript;

mod atoms {
    rustler::atoms! {
      ok,
      error,
      javascript,
      typescript,
      html
    }
}

#[derive(Clone, Debug, NifStruct)]
#[module = "Passwordless.Templating.MJMLRenderOptions"]
pub struct RenderOptions<'a> {
    pub keep_comments: bool,
    pub social_icon_path: Option<String>,
    pub fonts: Option<HashMap<Term<'a>, Term<'a>>>,
}

#[rustler::nif]
pub fn mjml_to_html<'a>(
    env: Env<'a>,
    mjml: String,
    render_options: RenderOptions,
) -> NifResult<Term<'a>> {
    return match mrml::parse(&mjml) {
        Ok(parsed) => {
            let options = mrml::prelude::render::RenderOptions {
                disable_comments: !render_options.keep_comments,
                social_icon_origin: social_icon_origin_option(render_options.social_icon_path),
                fonts: fonts_option(render_options.fonts),
            };

            return match parsed.element.render(&options) {
                Ok(content) => Ok((atoms::ok(), content).encode(env)),
                Err(error) => Ok((atoms::error(), error.to_string()).encode(env)),
            };
        }
        Err(error) => Ok((atoms::error(), error.to_string()).encode(env)),
    };
}

fn social_icon_origin_option(option_value: Option<String>) -> Option<Cow<'static, str>> {
    option_value.map_or(
        mrml::prelude::render::RenderOptions::default().social_icon_origin,
        |origin| Some(Owned(origin)),
    )
}

fn fonts_option<'a>(
    option_values: Option<HashMap<Term<'a>, Term<'a>>>,
) -> HashMap<String, Cow<'static, str>> {
    option_values.map_or(
        mrml::prelude::render::RenderOptions::default().fonts,
        |fonts| -> HashMap<String, Cow<'static, str>> {
            let mut options: HashMap<String, Cow<'static, str>> = HashMap::new();

            for (key, value) in fonts {
                let (k, v) = font_option(key, value);
                options.insert(k, v);
            }

            return options;
        },
    )
}

fn font_option<'a>(key: Term<'a>, value: Term<'a>) -> (String, Cow<'static, str>) {
    (
        match key.atom_to_string() {
            Ok(s) => s,
            Err(_) => panic!(
                "Keys for the `fonts` render option must be of type Atom, got {:?}.
                 Please use a Map like this: %{{\"My Font Name\": \"https://myfonts.example.com/css\"}}",
                key.get_type()
            )

        },
        match value.decode::<String>() {
            Ok(s) => Owned(s),
            Err(_) => panic!(
                "Values for the `fonts` render option must be of type String, got {:?}.
                 Please use a Map like this: %{{\"My Font Name\": \"https://myfonts.example.com/css\"}}",
                value.get_type()
            )
        }
    )
}

#[rustler::nif]
pub fn format_code(raw: String, language: Atom) -> String {
    match language {
        lang if lang == atoms::typescript() => format_ts("virtual.ts", "ts", raw),
        lang if lang == atoms::javascript() => format_ts("virtual.js", "js", raw),
        lang if lang == atoms::html() => format_html(raw),
        _ => raw,
    }
}

fn format_ts(file_name: &str, ext: &str, raw: String) -> String {
    let original = raw.clone();
    let config = ConfigurationBuilder::new()
        .line_width(120)
        .prefer_hanging(true)
        .prefer_single_line(false)
        .quote_style(QuoteStyle::PreferSingle)
        .next_control_flow_position(NextControlFlowPosition::SameLine)
        .build();

    format_typescript(Path::new(file_name), Some(ext), raw, &config)
        .ok()
        .flatten()
        .unwrap_or(original) // If there's an error or None, return an empty string
}

fn format_html(code: String) -> String {
    let options = FormatOptions {
        layout: LayoutOptions {
            print_width: 160,
            use_tabs: false,
            indent_width: 2,
            line_break: LineBreak::Lf,
        },
        language: LanguageOptions::default(),
    };

    match format_markup(&code, Language::Html, &options, |code, _| {
        Ok::<_, std::convert::Infallible>(code.into())
    }) {
        Ok(formatted) => formatted,
        Err(_) => code,
    }
}

rustler::init!("Elixir.Passwordless.Native");
