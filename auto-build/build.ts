import terser from "@rollup/plugin-terser"
import typescript from "@rollup/plugin-typescript"
import {generateDtsBundle} from "dts-bundle-generator"
import {writeFileSync} from "node:fs"
import {join} from "node:path"
import {OutputOptions, rollup, RollupOptions} from "rollup"

/**
 * How to externalize a import.
 * This function is defined as a template to be called frequently.
 *
 * @param source name of the source to import.
 * @param _importer this value is ignored, but necessary in parameter table.
 * @param isResolved whether such import is already resolved.
 * @returns whether such import should be externalized.
 */
function external(
  source: string,
  _importer: string | undefined,
  isResolved: boolean,
): boolean {
  if (isResolved) return false
  const libs = ["chalk", "dts-bundle-generator", "rollup", "yaml"]
  return (
    libs.includes(source) ||
    source.startsWith("node:") ||
    source.startsWith("@rollup/")
  )
}

/**
 * Build as a {@link RollupOptions} defined.
 * This is an encapsulation of building a rollup bundle as library.
 */
async function buildRollup(options: RollupOptions): Promise<void> {
  const bundle = await rollup(options)
  await (Array.isArray(options.output)
    ? Promise.allSettled(options.output.map(bundle.write))
    : bundle.write(options.output as OutputOptions))
  return bundle.close()
}

/**
 * Generate library output as the configurations inside "package.json".
 *
 * 1. The "package.json" file should apply the nodenext scheme.
 * 2. You should specify the "src" property inside the "exports" items
 *    to tell where the entrypoint is.
 *
 * Example of "package.json":
 *
 * ```json
 * {
 *   ...
 *   "exports": {
 *     "./name": {
 *       "src": "./src/name.ts",
 *       "types": "./out/name.d.ts",
 *       "import": "./out/name.js",
 *       "require": "./out/name.cjs"
 *     }
 *   }
 *   ...
 * }
 * ```
 *
 * @param root where the "package.json" locates.
 */
async function buildAsManifest(root: string): Promise<void> {
  const {exports} = await import(`${root}/package.json`)
  if (!exports || typeof exports !== "object") {
    throw new Error(`invalid package.json: ${join(root, "package.json")}`)
  }
  const tasks: Promise<void>[] = []
  for (const [key, value] of Object.entries(exports)) {
    // Validate values.
    if (typeof value !== "object") continue
    const src = (value as {[k: string]: any})["src"]
    if (typeof src !== "string") continue

    // Build libraries.
    const output: OutputOptions[] = []
    const i = (value as {[k: string]: any})["import"]
    const r = (value as {[k: string]: any})["require"]
    if (i) output.push({file: join(root, i), format: "esm", sourcemap: true})
    if (r) output.push({file: join(root, r), format: "cjs", sourcemap: true})
    const input = join(root, src)
    const plugins = [typescript(), terser()]
    tasks.push(buildRollup({plugins, external, input, output}))

    // Build declarations.
    const types = (value as {[k: string]: any})["types"]
    if (!types) continue
    const task = (async () => {
      const content = generateDtsBundle([{filePath: join(root, src)}])
      writeFileSync(join(root, types), content[0])
    })()
    tasks.push(task)
  }
  await Promise.allSettled(tasks)
}

/** Entrypoint. */
async function main() {
  const root = import.meta.dirname
  await buildAsManifest(root)
}
main()
