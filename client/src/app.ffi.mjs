import { Ok, Error } from "./gleam.mjs"

export function read_localstorage(key) {
	const value = window.localStorage.getItem(key)
	return value ? new Ok(JSON.parse(value)) : new Error(undefined)
}

export function write_localstorage(key, value) {
	console.log(value)
	window.localStorage.setItem(key, JSON.stringify(value))
}
