/*
 * AWSuite: http://forzefield.com
 *
 * Copyright (c) 2010 ForzeField Studios S.L.
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 * 
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 * 
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 *
 */

#import "AWTextureEffects.h"
#import "ccMacros.h"

@implementation AWTextureEffect

+ (void) blurInput:(void*)input output:(void*)output format:(CCTexture2DPixelFormat)format width:(int)width height:(int)height position:(ccGridSize)position size:(ccGridSize)size contentSize:(CGSize)contentSize radius:(int)radius
{
    int read, i, xl, yl, yi, ym, ri, riw;
	const int wh = width*height;
	
	size.x = (size.x==0) ? contentSize.width : size.x;
	size.y = (size.y==0) ? contentSize.height : size.y;
	
	//Check data
	position = ccg(MAX(0, position.x), MAX(0, position.y));
    size.x = position.x+size.x-MAX(0, (position.x+size.x)-width);
	size.y = position.y+size.y-MAX(0, (position.y+size.y)-height);
    yi = position.y*width;
	
	//Generate Gaussian kernel
    radius = MIN(MAX(1,radius), 248);
    int kernelSize = 1+radius*2;
    int kernel[kernelSize];	
    int g = 0, sum = 0;
	
	//Gaussian filter	
    for (i = 0; i<radius;i++)
	{
		g = i*i*i+1;
		kernel[i] = kernel[kernelSize-i-1] = g;
		sum+=g*2;
    }
	g = radius*radius;
    kernel[radius] = g;
    sum+=g;
	
	if(format == kTexture2DPixelFormat_RGBA8888){
		int cr, cg, cb, ca;

		const ccColor4B *originalData = (ccColor4B*)input;
		ccColor4B *data = (ccColor4B*)output;
		ccColor4B *temp = malloc(wh*4);
		ccColor4B *pixel;
		
		//Horizontal blur
		for (yl = position.y; yl<size.y; yl++){
			for (xl = position.x; xl<size.x; xl++){
				cb = cg = cr = ca = 0;
				ri = xl-radius;
				for (i = 0; i<kernelSize; i++){
					read = ri+i;
					if (read>=position.x && read<size.x){
						read+=yi;
						pixel = &originalData[read];
						cr+= pixel->r*kernel[i];
						cg+= pixel->g*kernel[i];
						cb+= pixel->b*kernel[i];
						ca+= pixel->a*kernel[i];
					}
				}
				ri = yi+xl;
				pixel = &temp[ri];
				pixel->r = cr/sum;
				pixel->g = cg/sum;
				pixel->b = cb/sum;
				pixel->a = ca/sum;
			}
			yi+=width;
		}
		yi = position.y*width;
		
		//Vertical blur
		for (yl = position.y; yl<size.y; yl++){
			ym = yl-radius;
			riw = ym*width;
			for (xl = position.x; xl<size.x; xl++){
				cb = cg = cr = ca = 0;
				ri = ym;
				read = xl+riw;
				for (i = 0; i<kernelSize; i++){
					if (ri<size.y && ri>=position.y){
						pixel = &temp[read];
						cr+= pixel->r * kernel[i];
						cg+= pixel->g * kernel[i];
						cb+= pixel->b * kernel[i];
						ca+= pixel->a * kernel[i];
					}
					ri++;
					read+=width;
				}
				pixel = &data[xl+yi];
				pixel->r = cr/sum;
				pixel->g = cg/sum;
				pixel->b = cb/sum;
				pixel->a = ca/sum;
			}
			yi+=width;
		}
		//Free temp data
		free(temp);
		
	}else if(format == kTexture2DPixelFormat_A8){
		int ca;

		const unsigned char *originalData = (const unsigned char*) input;
		unsigned char *data = (unsigned char*) output;
		unsigned char *temp = malloc(wh);
		
		//Horizontal blur
		for (yl = position.y; yl<size.y; yl++){
			for (xl = position.x; xl<size.x; xl++){
				ca = 0;
				ri = xl-radius;
				for (i = 0; i<kernelSize; i++){
					read = ri+i;
					if (read>=position.x && read<size.x){
						read+=yi;
						ca+=originalData[read] * kernel[i];
					}
				}
				ri = yi+xl;
				temp[ri] = ca/sum;;
			}
			yi+=width;
		}
		yi = position.y*width;
		
		//Vertical blur
		for (yl = position.y; yl<size.y; yl++){
			ym = yl-radius;
			riw = ym*width;
			for (xl = position.x; xl<size.x; xl++){
				ca = 0;
				ri = ym;
				read = xl+riw;
				for (i = 0; i<kernelSize; i++){
					if (ri<size.y && ri>=position.y)
						ca+=temp[read] * kernel[i];
						
					ri++;
					read+=width;
				}
				data[xl+yi] = ca/sum;;

			}
			yi+=width;
		}
		
		//Free temp data
		free(temp);
		
	}else
		[NSException raise:@"AWTextureEffect" format:@"Pixel format don't supported. It should be RGBA8888 or A8"];
}


+ (CCMutableTexture2D*) blur:(CCMutableTexture2D*)texture radius:(int)radius
{
	return [self blur:texture position:ccg(0,0) size:ccg(0,0) radius:radius];
}

+ (CCMutableTexture2D*) blur:(CCMutableTexture2D*)texture position:(ccGridSize)position size:(ccGridSize)size radius:(int)radius
{
	if(!texture)
		return nil;
	//Apply the effect to the texture
#ifdef CC_MUTABLE_TEXTURE_ORIGINAL_DATA
	[self blurInput:texture.originalTexData output:texture.texData format:texture.pixelFormat width:texture.pixelsWide height:texture.pixelsHigh position:position size:size contentSize:texture.contentSize radius:radius];
#else
	[self blurInput:texture.texData output:texture.texData format:texture.pixelFormat width:texture.pixelsWide height:texture.pixelsHigh position:position size:size contentSize:texture.contentSize radius:radius];
#endif
	//Update the GPU data
	[texture apply];
	
	return texture;
}
																												

@end