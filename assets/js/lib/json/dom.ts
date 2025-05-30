export function element(name: string) {
	return document.createElement(name);
}

export function append(target: HTMLElement, node: Node) {
	target.appendChild(node);
}

export function listen(
	node: Node,
	event: string,
	handler: EventListenerOrEventListenerObject
) {
	node.addEventListener(event, handler);
	return () => node.removeEventListener(event, handler);
}

export function detach(node: Node) {
	node.parentNode?.removeChild(node);
}
