const {
  expectBrowserSpec,
  expectAccepted,
  expectRejected,
  reportLine
} = require("./helpers/SpecHelpers")

describe("Events", () => {
  context("click", () => {
    it("handles the click event as expected", (done) => {
      expectBrowserSpec("EventSpec", "click", done, (observations) => {
        expectAccepted(observations[0])
        expectRejected(observations[1], [
          reportLine("No element targeted for event", "click")
        ])
      })
    })
  })

  context.only("press", () => {
    it("handles the mousedown event as expected", (done) => {
      expectBrowserSpec("EventSpec", "mouseDown", done, (observations) => {
        expectAccepted(observations[0])
        expectRejected(observations[1], [
          reportLine("No element targeted for event", "mousedown")
        ])
      })
    })
  })

  describe("Input", () => {
    context("when text is input to a targeted field", () => {
      it("updates the model and renders the view as expected", (done) => {
        expectBrowserSpec("EventSpec", "input", done, (observations) => {
          expectAccepted(observations[0])
          expectRejected(observations[1], [
            reportLine("No element targeted for event", "input")
          ])
        })
      })
    })
  })

  describe("custom events", () => {
    context("when a custom event is triggered", () => {
      it("updates as expected", (done) => {
        expectBrowserSpec("EventSpec", "custom", done, (observations) => {
          expectAccepted(observations[0])
          expectRejected(observations[1], [
            reportLine("No element targeted for event", "keyup")
          ])
        })
      })
    })
  })
})