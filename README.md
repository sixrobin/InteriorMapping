# Interior Mapping
![Render_01_Crop](https://github.com/sixrobin/InteriorMapping/assets/55784799/39857c15-be4e-4942-9c61-43b86c971132)

Interior mapping implementation in Unity. The projects features an object space interior mapping shader, with some additional features detailed below.
The implementation uses the technique explained [in this document](https://www.proun-game.com/Oogst3D/CODING/InteriorMapping/InteriorMapping.pdf).

## Basic algorithm
The basic interior mapping works on objects with the same scale on x and z axis, such as a cube, but that can be scaled on the y axis. Objects with a different scale on x and z axis will technically work, but the shader will use the same values for both axis, which can make one of them look stretched.
The Unity's native cube has one of its face with inverted UV y axis, so the project includes a simple script that generates a mesh with a UV mapping fitting the mapping.

The walls can handle any number of rooms, whether it's even or odd, or different for the width and height. The roof will work fine only when the same value is used.

Walls texturing works with a sprite sheet (imported as a 2DArray). The shaders randomly samples a texture from the sheet and applies it to walls. Same goes for floors and ceilings.

![interiormapping-ezgif com-optimizef](https://github.com/sixrobin/InteriorMapping/assets/55784799/04f3a208-5494-4e8d-8522-1ffabaf24c1a)

## Windows
Windows are textures that are applied to the mesh faces, scaling the UV using the desired rooms count. Windows may be transparent textures, so they require a mask to know where the glass is: when displaying the window, if the sampled pixel is transparent, then the mask is checked: if it's the glass part of the window, then the room interior is drawn, else, the outside wall is drawn instead.

Windows are discarded on roof, and can also be discarded on how many floors as desired, starting from the bottom one.

![windows-ezgif com-speed](https://github.com/sixrobin/InteriorMapping/assets/55784799/ae513822-42d1-4856-b79b-6ef5dbce5bac)

## Additional features
### Shutters
Shutters can be added to windows. Shutters can either be fully closed using a slider to control the amount of shutters that should be closed, or they can close gradually, using another slider to control the closing percentage across the object. Both sliders can work together.

For rooms with shutters closing gradually, when the shutter is getting fully closed, the rooms gets darker.

![shutters](https://github.com/sixrobin/InteriorMapping/assets/55784799/04fb0d42-7e1a-4d52-9592-123a3f98ed2f)

### Interior lighting
Rooms interior can be lit using a given color. This color is HDR, meaning the color can work well with bloom effects. The amount of rooms with lighting is controled by a slider.

Interior lighting works fine with shutters, although rooms that are lit will not get darker according the their shutters opening state (this can be changed if needed, it's been implemented like so as I found this visually more pleasing).

![room light](https://github.com/sixrobin/InteriorMapping/assets/55784799/154f8e93-c7cd-4582-9ad1-b134654b2fd9)

### Windows glass color and refaction
Window glasses can be tinted, and a fake refraction effect can be applied on window glasses. The effect simply offsets the interior mapping raycast randomly for each pixel, which makes the effect very noisy, but working pretty fine with a small refraction intensity.

![windowglass-ezgif com-optimize](https://github.com/sixrobin/InteriorMapping/assets/55784799/7d55d236-99a3-4cb5-980f-792b4ecc932a)
