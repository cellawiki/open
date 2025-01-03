import {join} from "node:path"
import {describe, expect, test} from "vitest"
import {diffPath} from "./format"

describe(diffPath.name, function () {
  test("normal", function () {
    const a = join("same", "path", "diff.a")
    const b = join("same", "path", "diff", "b.ext")
    expect(diffPath(a, b)).toStrictEqual({
      common: join("same", "path"),
      from: join("diff.a"),
      to: join("diff", "b.ext"),
    })
  })

  test("append", function () {
    const a = join("same", "path")
    const b = join("same", "path", "diff")
    expect(diffPath(a, b)).toStrictEqual({
      common: a,
      from: "",
      to: join("diff"),
    })
  })

  test("same", function () {
    const a = join("same", "path")
    const b = join("same", "path")
    const handler = expect(diffPath(a, b))
    handler.toStrictEqual({common: a, from: "", to: ""})
    handler.toStrictEqual({common: b, from: "", to: ""})
  })

  test("completely different", function () {
    const a = join("path", "a")
    const b = join("diff", "path", "b")
    expect(diffPath(a, b)).toStrictEqual({common: "", from: a, to: b})
  })
})
