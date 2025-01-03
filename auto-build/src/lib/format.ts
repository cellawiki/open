import chalk, {ChalkInstance} from "chalk"
import {parse, sep} from "node:path"

/** Format a path with colors that with dim base and colored name. */
export function formatPath(raw: string, color: ChalkInstance) {
  const path = parse(raw)
  const dim = chalk.dim
  const dir = path.dir
  if (dir === "") return color(path.base)
  return `${dim(dir)}${dim(sep)}${color(path.base)}`
}

/**
 * The information data type defined on
 * the differences information between two paths.
 */
export interface DiffInfo {
  common: string
  from: string
  to: string
}

/** Parse the difference information between the two path. */
export function diffPath(from: string, to: string): DiffInfo {
  const fromParts = from.split(sep)
  const toParts = to.split(sep)
  for (let i = 0; i < Math.max(fromParts.length, toParts.length); i++) {
    if (fromParts[i] !== toParts[i]) {
      return {
        common: fromParts.slice(0, i).join(sep),
        from: fromParts.slice(i).join(sep),
        to: toParts.slice(i).join(sep),
      }
    }
  }
  return {common: from, from: "", to: ""}
}

/** Format move from a path and to another path. */
export function formatMove(from: string, to: string, color: ChalkInstance) {
  const diff = diffPath(from, to)
  if (from === "") from = "."
  if (to === "") to = "."
  if (diff.from === "." && diff.to === ".") {
    return `${formatPath(diff.common, color)} ${chalk.dim("(self)")}`
  }
  return [
    chalk.dim(diff.common),
    chalk.dim(" ("),
    formatPath(diff.from, color.dim),
    chalk.dim(" => "),
    formatPath(diff.to, color),
    chalk.dim(")"),
  ].join("")
}
