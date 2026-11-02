import Testing
@testable import DartBuddy

private let width = 200
private let height = 120

private func blankImage() -> LumaImage {
    LumaImage(width: width, height: height, pixels: Array(repeating: 100, count: width * height))!
}

private func paint(_ image: inout LumaImage, x: ClosedRange<Int>, y: ClosedRange<Int>, value: UInt8) {
    for row in y {
        for column in x {
            image.pixels[row * width + column] = value
        }
    }
}

/// Bright 12x12 flight at x 140...151 with an optional dark 3 px barrel running left to x = 90.
private func dartImage(withBarrel: Bool) -> LumaImage {
    var image = blankImage()
    paint(&image, x: 140 ... 151, y: 40 ... 51, value: 220)
    if withBarrel {
        paint(&image, x: 90 ... 139, y: 45 ... 47, value: 30)
    }
    return image
}

private let wholeImage = DartTipLocator.PixelRect(minX: 0, minY: 0, maxX: width - 1, maxY: height - 1)

@Test(.tags(.unit, .vision, .regression))
func tipLocatorFindsBarrelEndWithPoseHint() throws {
    let tip = try #require(DartTipLocator.locateTip(
        baseline: blankImage(),
        current: dartImage(withBarrel: true),
        in: wholeImage,
        flightToTip: SIMD2(-55, 0)
    ))
    #expect(abs(tip.x - 90.5) < 2)
    #expect(abs(tip.y - 46) < 2)
}

@Test(.tags(.unit, .vision, .regression))
func tipLocatorPicksNarrowEndWithoutHint() throws {
    let tip = try #require(DartTipLocator.locateTip(
        baseline: blankImage(),
        current: dartImage(withBarrel: true),
        in: wholeImage,
        flightToTip: nil
    ))
    #expect(abs(tip.x - 90.5) < 2)
}

@Test(.tags(.unit, .vision, .regression))
func tipLocatorStepsFromFlightWhenBarrelIsMissing() throws {
    let tip = try #require(DartTipLocator.locateTip(
        baseline: blankImage(),
        current: dartImage(withBarrel: false),
        in: wholeImage,
        flightToTip: SIMD2(-55, 0)
    ))
    #expect(abs(tip.x - (146 - 55)) < 1)
    #expect(abs(tip.y - 46) < 1)
}

@Test(.tags(.unit, .vision, .regression))
func tipLocatorFindsTheLowerEndOfAVerticalDart() throws {
    var image = blankImage()
    paint(&image, x: 94 ... 106, y: 20 ... 32, value: 220)
    paint(&image, x: 99 ... 101, y: 33 ... 90, value: 30)
    let tip = try #require(DartTipLocator.locateTip(
        baseline: blankImage(),
        current: image,
        in: wholeImage,
        flightToTip: SIMD2(0, 50)
    ))
    #expect(abs(tip.x - 100.5) < 4)
    #expect(abs(tip.y - 90.5) < 4)
}

@Test(.tags(.unit, .vision, .regression))
func tipLocatorIgnoresUnchangedFrames() {
    #expect(DartTipLocator.locateTip(
        baseline: blankImage(),
        current: blankImage(),
        in: wholeImage,
        flightToTip: SIMD2(-55, 0)
    ) == nil)
}
