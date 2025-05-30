const S3 = (entries: any[], onViewError: (callback: () => void) => void) => {
	for (const entry of entries) {
		const xhr = new XMLHttpRequest();
		onViewError(() => xhr.abort());
		xhr.onload = () =>
			xhr.status === 200 ? entry.progress(100) : entry.error();
		xhr.onerror = () => entry.error();

		xhr.upload.addEventListener("progress", (event) => {
			if (event.lengthComputable) {
				const percent = Math.round((event.loaded / event.total) * 100);
				if (percent < 100) {
					entry.progress(percent);
				}
			}
		});

		const url = entry.meta.url;
		xhr.open("PUT", url, true);
		xhr.send(entry.file);
	}
};

export default {
	S3,
};
