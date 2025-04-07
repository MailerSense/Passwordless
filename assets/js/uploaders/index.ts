const S3 = function (
  entries: any[],
  onViewError: (callback: () => void) => void,
) {
  entries.forEach((entry) => {
    const formData = new FormData();
    const { url, fields } = entry.meta;

    Object.entries(fields).forEach(([key, value]) => {
      formData.append(key, value as string);
    });
    formData.append("file", entry.file);

    // Build the request
    const req = new XMLHttpRequest();
    onViewError(() => req.abort());
    req.onload = () => {
      req.status >= 200 && req.status < 300
        ? entry.progress(100)
        : entry.error();
    };
    req.onerror = () => {
      entry.error();
    };

    // Adds an event listener for upload progress, to enable an upload progress bar
    req.upload.addEventListener("progress", (event) => {
      if (event.lengthComputable) {
        const progressPercent = Math.round((event.loaded / event.total) * 100);
        if (progressPercent < 100) {
          entry.progress(progressPercent);
        }
      }
    });

    req.open("POST", url, true);
    req.send(formData);
  });
};

export default {
  S3,
};
