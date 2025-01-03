import chalk from "chalk"
import {copyFileSync, readFileSync, writeFileSync} from "node:fs"
import {basename, join} from "node:path"
import * as yaml from "yaml"
import {formatMove} from "./format"

/** Logger code reuse. */
const sync = chalk.dim.green("sync")

/**
 * Sync license file from the monorepo to current child repo.
 * @param root the folder where "LICENSE" of current child repo locates.
 * @param monorepo the folder where "LICENSE" of the monorepo locates.
 */
export function syncLicense(root: string, monorepo: string, log = true) {
  const filename = "license".toUpperCase()
  const src = join(monorepo, filename)
  const out = join(root, filename)
  copyFileSync(src, out)

  if (log) console.log(`${sync} ${formatMove(src, out, chalk.magenta)}`)
}

/**
 * Sync all related contributors from the monorepo root to current child repo.
 * @param root the folder where "CONTRIBUTORS.yaml" of current repo locates.
 * @param monorepo the folder where "CONTRIBUTORS.yaml" of monorepo locates.
 */
export function syncContributors(root: string, monorepo: string, log = true) {
  const filename = `${"contributors".toUpperCase()}.yaml`
  const name = basename(root)
  const src = join(monorepo, filename)
  const raw = yaml.parse(readFileSync(src).toString())
  const handler: {[key: string]: any} = {}
  for (const [author, data] of Object.entries(raw)) {
    if (!data) continue
    const repo = (data as any)["repo"]
    if (typeof repo === name || (Array.isArray(repo) && repo.includes(name))) {
      handler[author] = {...data, repo: undefined}
    }
  }
  const content = yaml.stringify(handler)
  const out = join(root, filename)
  writeFileSync(out, content)

  if (log) console.log(`${sync} ${formatMove(src, out, chalk.magenta)}`)
}
