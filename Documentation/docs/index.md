# ZirconCropper

ZirconCropper is a control that allows the user to zoom and crop an image.

## Requirements

This control requires Xojo 2019r3.2 and [Artisan Kit 1.2.2](https://github.com/thommcgrath/ArtisanKit/releases/). Only desktop projects are supported.

## Installation

Open the binary project and copy both the ZirconCropper class and ArtisanKit module into your project. If you already use Artisan Kit and encounter compile errors with the control, your ArtisanKit module needs to be updated to the included version.

## Events

<pre id="event.sourceimagepresented"><span style="font-family: 'source-code-pro', 'menlo', 'courier', monospace; color: #000000;"><span style="color: #0000ff;">Event</span> SourceImagePresented (Source <span style="color: #0000ff;">As</span> Picture)</span></pre>
This event triggers when the source image is changed. The `Source` parameter may be nil, such as when the `Clear` method is called.

<pre id="event.sourceimagepresenting"><span style="font-family: 'source-code-pro', 'menlo', 'courier', monospace; color: #000000;"><span style="color: #0000ff;">Event</span> SourceImagePresenting (Source <span style="color: #0000ff;">As</span> Picture)</span></pre>
This event triggers just before the source image is changed. The `Source` parameter will never be nil. Feel free to make changes to the image, but do not replace the value of the `Source` parameter.

## Properties

<pre id="property.backgroundcolor"><span style="font-family: 'source-code-pro', 'menlo', 'courier', monospace; color: #000000;">BackgroundColor <span style="color: #0000ff;">As</span> <span style="color: #0000ff;">Color</span></span></pre>
Set the background color of the control. Frame and zoom controls will automatically adjust their colors based on the background color. The background color is not applied to the cropped images.

<pre id="property.hasbackgroundcolor"><span style="font-family: 'source-code-pro', 'menlo', 'courier', monospace; color: #000000;">HasBackgroundColor <span style="color: #0000ff;">As</span> <span style="color: #0000ff;">Boolean</span></span></pre>
By default the control will draw be transparent. Set this to true to have the control's background filled with the color specified by the `BackgroundColor` property.

## Methods

<pre id="method.clear"><span style="font-family: 'source-code-pro', 'menlo', 'courier', monospace; color: #000000;"><span style="color: #0000ff;">Sub</span> Clear ()</span></pre>
Call this method to reset the cropper to its default state. This will trigger the `SourceImagePresented` event, but not the `SourceImagePresenting` event.

<pre id="method.crop"><span style="font-family: 'source-code-pro', 'menlo', 'courier', monospace; color: #000000;"><span style="color: #0000ff;">Function</span> Crop () <span style="color: #0000ff;">As</span> Picture</span></pre>
After you have supplied a picture and desired size using the `Present` method, the `Crop` method returns the cropped image as a multi-resolution picture.

<pre id="method.present"><span style="font-family: 'source-code-pro', 'menlo', 'courier', monospace; color: #000000;"><span style="color: #0000ff;">Sub</span> Present (Source <span style="color: #0000ff;">As</span> Picture, DesiredWidth <span style="color: #0000ff;">As</span> <span style="color: #0000ff;">Integer</span>, DesiredHeight <span style="color: #0000ff;">As</span> <span style="color: #0000ff;">Integer</span>)</span></pre>
Sets the cropper to display the `Source` parameter to be cropped to `DesiredWidth` and `DesiredHeight`.

<pre id="method.update"><span style="font-family: 'source-code-pro', 'menlo', 'courier', monospace; color: #000000;"><span style="color: #0000ff;">Sub</span> Update (Source <span style="color: #0000ff;">As</span> Picture)</span></pre>
Allows immediately setting the displayed image without changing anything else, such as the zoom level. The `SourceImagePresenting` and `SourceImagePresented` events will not fire.