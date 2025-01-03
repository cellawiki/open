import {describe, expect, test} from "vitest"
import {packageNameRegex, parseDependencies} from "./bundle"

describe("parse dependencies", () => {
  test("invalid input", () => {
    expect(parseDependencies(123)).toStrictEqual([])
    expect(parseDependencies("abc")).toStrictEqual([])
    expect(parseDependencies(true)).toStrictEqual([])
    expect(parseDependencies(false)).toStrictEqual([])
  })

  test("regexp", () => {
    expect(packageNameRegex().test("@drawidgets/demo")).toBe(true)
    expect(packageNameRegex().test("@rollup/plugin-typescript")).toBe(true)
    expect(packageNameRegex().test("@drawidgets/demo/invalid")).toBe(false)
    expect(packageNameRegex().test("chalk")).toBe(true)
    expect(packageNameRegex().test("invalid@name")).toBe(false)
  })

  test("filter dependencies", () => {
    const example = {
      "@drawidgets/demo": "workspace:*",
      "@types/node": "^22.0.0",
      chalk: "^5.0.0",
      "invalid-value": "invalid",
      "@invalid.format": "^1.2.3",
      "invalid@format": "^4.5.6",
    }
    expect(parseDependencies({dependencies: example})).toStrictEqual([
      "@drawidgets/demo",
      "@types/node",
      "chalk",
      "invalid-value",
    ])
  })
})
