varying vec3 v_position;
			varying vec4 v_nearpos;
			varying vec4 v_farpos;
			varying vec3 worldSpaceCoords;
			varying vec4 projectedCoords;


			uniform sampler2D tex, cubeTex, transferTex;
			uniform float steps;
			uniform float slice;
			uniform float tiles;
			uniform float alphaCorrection;
			uniform float spacex, spacey, spacez;
			
			// The maximum distance through our rendering volume is sqrt(3).
			// The maximum number of steps we take to travel a distance of 1 is 512.
			// ceil( sqrt(3) * 512 ) = 887
			// This prevents the back of the image from getting cut off when steps=512 & viewing diagonally.
			
			const int MAX_STEPS = 887;
			const float MAXZ = 45.0;

			//const int MAX_STEPS = 887;	// 887 for 512^3, 1774 for 1024^3
			const int REFINEMENT_STEPS = 100;
			const float relative_step_size = 0.000001;
			const vec4 ambient_color = vec4(0.2, 0.4, 0.2, 1.0);
			const vec4 diffuse_color = vec4(0.8, 0.2, 0.2, 1.0);
			const vec4 specular_color = vec4(1.0, 1.0, 1.0, 1.0);
			const float shininess = 40.0;
			

			
			//const float tiles = 6.0;
		
			//Acts like a texture3D using Z slices and trilinear filtering.
			vec4 sampleAs3DTexture( vec3 texCoord )
			{
				//texCoord.xy *= ;

				vec3 texCoord2 = vec3( 
									texCoord.x * spacex,
									texCoord.y * spacey,
									texCoord.z * spacez - (spacez-1.0)/2.0
								);

				//if( texCoord2.z < 0.0 ) 
				//	texCoord2.z = 0.0;
				
				//if( texCoord2.z > 1.0 ) 
				//	texCoord2.z = 1.0;

				float maxTiles = tiles*tiles-1.0;
				vec4 colorSlice1, colorSlice2;
				vec2 texCoordSlice1, texCoordSlice2;

				//The z coordinate determines which Z slice we have to look for.
				//Z slice number goes from 0 to 255.
				//int z=  int(floor(texCoord2.z * maxTiles));
				//float zSliceNumber1 = float(z);

				float z = texCoord.z * spacez - (spacez-1.0)/2.0;
				//float maxTiles = tiles*tiles-1.0;
				
				int zSliceNumber1int = int(min( floor(z * maxTiles), maxTiles));
				float zSliceNumber1 = float(zSliceNumber1int);


					//As we use trilinear we go the next Z slice.
				//float zSliceNumber2 = min( zSliceNumber1 + 1.0, MAXZ); //Clamp to 255

				//The Z slices are stored in a matrix of 16x16 of Z slices.
				//The original UV coordinates have to be rescaled by the tile numbers in each row and column.
				texCoord2.xy /= tiles;

				texCoordSlice1 = texCoord2.xy;
				//texCoordSlice2 = texCoord2.xy;

				//Add an offset to the original UV coordinates depending on the row and column number.

				int x = zSliceNumber1int;
				x -= int(tiles) * (x / int(tiles));
				texCoordSlice1.x += float( x ) / tiles;
				
				//texCoordSlice1.x += float(mod( 36, 7 )) / tiles;
				int y = 0;
				
				y = (int(tiles)*int(tiles) - zSliceNumber1int -1);
				y /= int(tiles);
				//y = floor(y);
				texCoordSlice1.y += float(y) / tiles;

				//texCoordSlice1.x += 1.0/7.0;
				//texCoordSlice1.y += 1.0/7.0;

				//texCoordSlice1.x = min(max(texCoordSlice1.x,0.0),1.0);
				//texCoordSlice1.y = min(max(texCoordSlice1.y,0.0),1.0);

				//texCoordSlice1.xy *= 0.538330078;
				//texCoordSlice1.y += 5.0/6.0;


				//texCoordSlice1.x += 0.538330078;
				//texCoordSlice1.xy = texCoordSlice1.yx;

				//texCoordSlice2.x += (mod(zSliceNumber2, tiles ) / tiles);
				//texCoordSlice2.y += floor((maxTiles - zSliceNumber2) / tiles) / tiles;

				//Get the opacity value from the 2D texture.
				//Bilinear filtering is done at each texture2D by default.
				colorSlice1 = texture2D( cubeTex, texCoordSlice1 );
				//colorSlice2 = texture2D( cubeTex, texCoordSlice2 );

				//Based on the opacity obtained earlier, get the RGB color in the transfer function texture.
				//colorSlice1.rgb = texture2D( transferTex, vec2( colorSlice1.r, 1.0) ).rgb;
				//colorSlice2.rgb = texture2D( transferTex, vec2( colorSlice2.r, 1.0) ).rgb;

				//How distant is zSlice1 to ZSlice2. Used to interpolate between one Z slice and the other.
				//float zDifference = mod(texCoord2.z * maxTiles, 1.0);
				//float zDifference = mod(texCoord2.z * maxTiles, 1.0);

				//Finally interpolate between the two intermediate colors of each Z slice.
				//if( zSliceNumber1int == int(slice))
				//	return colorSlice1 + vec4(1.0, 1.0, 0.0, 0.1);
				//else if( zSliceNumber1int == 39)
				//	return colorSlice1 + vec4(1.0, 0.0, 0.0, 0.1);
				//else
					return colorSlice1;
				//mix(colorSlice1, colorSlice2, 1.0) ;
				
			}

			float sampleAs3DTextureRed( vec3 texCoord )
			{
				float maxTiles = tiles*tiles-1.0;
				vec4 colorSlice1, colorSlice2;
				vec2 texCoordSlice1, texCoordSlice2;

				//The z coordinate determines which Z slice we have to look for.
				//Z slice number goes from 0 to 255.
				float zSliceNumber1 = floor(texCoord.z * MAXZ);

					//As we use trilinear we go the next Z slice.
				float zSliceNumber2 = min( zSliceNumber1 + 1.0, MAXZ); //Clamp to 255

				//The Z slices are stored in a matrix of 16x16 of Z slices.
				//The original UV coordinates have to be rescaled by the tile numbers in each row and column.
				texCoord.xy /= tiles;

				texCoordSlice1 = texCoordSlice2 = texCoord.xy;

				//Add an offset to the original UV coordinates depending on the row and column number.
				texCoordSlice1.x += (mod(zSliceNumber1, tiles ) / tiles);
				texCoordSlice1.y += floor((maxTiles - zSliceNumber1) / tiles) / tiles;

				texCoordSlice2.x += (mod(zSliceNumber2, tiles ) / tiles);
				texCoordSlice2.y += floor((maxTiles - zSliceNumber2) / tiles) / tiles;

				//Get the opacity value from the 2D texture.
				//Bilinear filtering is done at each texture2D by default.
				colorSlice1 = texture2D( cubeTex, texCoordSlice1 );
				//colorSlice2 = texture2D( cubeTex, texCoordSlice2 );

				//Based on the opacity obtained earlier, get the RGB color in the transfer function texture.
				//colorSlice1.rgb = texture2D( transferTex, vec2( colorSlice1.r, 1.0) ).rgb;
				//colorSlice2.rgb = texture2D( transferTex, vec2( colorSlice2.r, 1.0) ).rgb;

				//How distant is zSlice1 to ZSlice2. Used to interpolate between one Z slice and the other.
				//float zDifference = mod(texCoord.z * maxTiles, 1.0);
				//float zDifference = mod(texCoord.z * MAXZ, 1.0);

				//Finally interpolate between the two intermediate colors of each Z slice.
				return colorSlice1.r;
				//mix(colorSlice1, colorSlice2, 1.0) ;
				
			}
			void cast_mip(vec3 start_loc, vec3 step, int nsteps, vec3 view_ray);

			void main( void ) {

				//Transform the coordinates it from [-1;1] to [0;1]
				vec2 texc = vec2(((projectedCoords.x / projectedCoords.w) + 1.0 ) / 2.0,
								((projectedCoords.y / projectedCoords.w) + 1.0 ) / 2.0 );

				//The back position is the world space position stored in the texture.
				vec3 backPos = texture2D(tex, texc).xyz;

				//The front position is the world space position of the second render pass.
				vec3 frontPos = worldSpaceCoords;

				//Using NearestFilter for rtTexture mostly eliminates bad backPos values at the edges
				//of the cube, but there may still be no valid backPos value for the current fragment.
				if ((backPos.x == 0.0) && (backPos.y == 0.0))
				{
					gl_FragColor = vec4(0.0);
					return;
				}

				//The direction from the front position to back position.
				vec3 dir = backPos - frontPos;

				float rayLength = length(dir);

				//Calculate how long to increment in each step.
				float delta = 1.0 / steps;

				//The increment in each direction for each step.
				vec3 deltaDirection = normalize(dir) * delta;
				float deltaDirectionLength = length(deltaDirection);

				//Start the ray casting from the front position.
				vec3 currentPosition = frontPos;

				//The color accumulator.
				vec4 accumulatedColor = vec4(0.0);

				//The alpha value accumulated so far.
				float accumulatedAlpha = 0.0;

				//How long has the ray travelled so far.
				float accumulatedLength = 0.0; 

				//If we have twice as many samples, we only need ~1/2 the alpha per sample.
				//Scaling by 256/10 just happens to give a good value for the alphaCorrection slider.
				float alphaScaleFactor = 25.6 * delta;

				vec4 prevSample = sampleAs3DTexture( currentPosition );
				vec4 colorSample;
				float alphaSample;

				//Perform the ray marching iterations
				for(int i = 0; i < MAX_STEPS; i++)
				{
					//Get the voxel intensity value from the 3D texture.
					
					colorSample = sampleAs3DTexture( currentPosition );

					/*if( colorSample.g > colorSample.r ) {
						colorSample.rgb = vec3(1.0,1.0,1.0);
						alphaSample = colorSample.a * 0.1;
					}
					else
					{*/
						/*float z = currentPosition.z * spacez - (spacez-1.0)/2.0;
						float maxTiles = tiles*tiles-1.0;
						float zSliceNumber1 = float(int(floor(z * maxTiles)));


						

						if( int(slice) == int(zSliceNumber1) )
						{
							colorSample += vec4(1.0,1.0,1.0,1.0);
						}*/
						
							alphaSample = colorSample.a * 0.4;
						
					//}

					if( prevSample.r == colorSample.r
					&& prevSample.g == colorSample.g
					&& prevSample.b == colorSample.b ) {
						prevSample = colorSample;
						currentPosition += deltaDirection;
						accumulatedLength += deltaDirectionLength;

						//If the length traversed is more than the ray length, or if the alpha accumulated reaches 1.0 then exit.
						if(accumulatedLength >= rayLength || accumulatedAlpha >= 1.0 )
							break;

						continue;
					}

			
						

					//Applying this effect to both the color and alpha accumulation results in more realistic transparency.
					alphaSample *= (1.0 - accumulatedAlpha);

					//Scaling alpha by the number of steps makes the final color invariant to the step size.
					alphaSample *= alphaScaleFactor;

					//Perform the composition.
					//accumulatedColor += colorSample * alphaSample;
					accumulatedColor = vec4(colorSample.rgb * colorSample.a * alphaCorrection / 10.0 + accumulatedColor.rgb * (1.0 -colorSample.a * alphaCorrection / 10.0),1.0);

					//Store the alpha accumulated so far.
					accumulatedAlpha += alphaSample;

					//Advance the ray.
					prevSample = colorSample;
					currentPosition += deltaDirection;
					accumulatedLength += deltaDirectionLength;

					//int refineSteps = 100;
					/*vec3 refinePos = currentPosition - deltaDirection / 2.0;
					vec3 refineDir = deltaDirection / float(REFINEMENT_STEPS ); 
					for(int i = 0; i < REFINEMENT_STEPS ; i++)
					{
						colorSample = sampleAs3DTexture( refinePos );
						alphaSample = colorSample.a * 0.4;

						accumulatedColor = vec4(colorSample.rgb * colorSample.a * alphaCorrection / 200.0 + accumulatedColor.rgb * (1.0 -colorSample.a * alphaCorrection / 200.0),1.0);

						refinePos += refineDir;
					}*/


					//If the length traversed is more than the ray length, or if the alpha accumulated reaches 1.0 then exit.
					if(accumulatedLength >= rayLength || accumulatedAlpha >= 1.0 )
						break;
				}

				/*if( accumulatedColor.a > 0.0 )
				{
					
					float min = 0.1;
					
					if( accumulatedColor.r == accumulatedColor.b
					 && accumulatedColor.r == accumulatedColor.g
					 && accumulatedColor.r < min ) {
						 
							accumulatedColor.r = 1.0;
						 accumulatedColor.g = 1.0;
						 accumulatedColor.b = 1.0;
						 accumulatedColor.a = 0.1;
					 }
					//max(accumulatedColor.a, 1.0);
				}*/

				gl_FragColor  = accumulatedColor;

			}

			void main2( void ) {

				vec3 u_size = vec3(630.0,630.0,630.0);
				// Normalize clipping plane info

				vec3 farpos = v_farpos.xyz / v_farpos.w;
				vec3 nearpos = v_nearpos.xyz / v_nearpos.w;

				// Calculate unit vector pointing in the view direction through this fragment.
				vec3 view_ray = normalize(nearpos.xyz - farpos.xyz);
				view_ray.xyz /= 30.0;

				// Compute the (negative) distance to the front surface or near clipping plane.
				// v_position is the back face of the cuboid, so the initial distance calculated in the dot
				// product below is the distance from near clip plane to the back of the cuboid
				
				float distance = dot(nearpos - v_position, view_ray);
				//distance = max(distance, min((-0.5 - v_position.x) / view_ray.x, (u_size.x - 0.5 - v_position.x) / view_ray.x));
				//distance = max(distance, min((-0.5 - v_position.y) / view_ray.y, (u_size.y - 0.5 - v_position.y) / view_ray.y));
				//distance = max(distance, min((-0.5 - v_position.z) / view_ray.z, (u_size.z - 0.5 - v_position.z) / view_ray.z));

				float distance2 = dot(farpos - v_position, view_ray);
				// Now we have the starting position on the front surface
				vec3 front = v_position + view_ray * distance;

				// Decide how many steps to take
				int nsteps = int(-distance / relative_step_size);
				if ( nsteps < 1 )
						discard;

						
				// Get starting location and step vector in texture coordinates
				
				vec3 step = ((v_position - front) / u_size) / float(nsteps);
				/*vec3 start_loc = front / u_size;

				// For testing: show the number of steps. This helps to establish
				// whether the rays are correctly oriented
				//gl_FragColor = vec4(0.0, float(nsteps) / 1.0 / u_size.x, 1.0, 1.0);
				
			*/
				//vec2 texc = vec2(((v_position.x / v_position.w) + 1.0 ) / 2.0,
				//				((v_position.y / v_position.w) + 1.0 ) / 2.0 );

				//vec3 start_loc2 = vec3( v_position.xyz );
				//start_loc2.x = ((start_loc2.x / v_position.w) + 1.0 ) / 2.0;
				//start_loc2.y -= (0.5*630.0)/630.0;
				//start_loc2.z  = 42.0/49.0;

				float nstepsf = float(nsteps);// / 20.0;
				//view_ray.xyz *= 630.0;
				//gl_FragColor = sampleAs3DTexture(worldSpaceCoords);
				//gl_FragColor = vec4(1.0,nstepsf,nstepsf,1.0);
				
				


				cast_mip(worldSpaceCoords, step, nsteps, view_ray);

				if (gl_FragColor.a < 0.05)
					discard;
			/*
				if (u_renderstyle == 0)
						cast_mip(start_loc, step, nsteps, view_ray);
				else if (u_renderstyle == 1)
						cast_iso(start_loc, step, nsteps, view_ray);

				if (gl_FragColor.a < 0.05)
						discard;
		
				vec4 colorSample;
				colorSample = sampleAs3DTexture( v_position );
				colorSample.a = 0.1;
				gl_FragColor = colorSample;
*/
			}

			void cast_mip(vec3 start_loc, vec3 step, int nsteps, vec3 view_ray) {

				float max_val = -1e6;
				int max_i = 0;
				vec3 loc = start_loc;

				// Enter the raycasting loop. In WebGL 1 the loop index cannot be compared with
				// non-constant expression. So we use a hard-coded max, and an additional condition
				// inside the loop.
				for (int iter=0; iter<MAX_STEPS; iter++) {
					if (iter >= nsteps)
							break;

					// Sample from the 3D texture
					float val = sampleAs3DTextureRed(loc);
					
					// Apply MIP operation
					if (val > max_val) {
							max_val = val;
							max_i = iter;
					}
					
					// Advance location deeper into the volume
					loc += view_ray;
				}

				/*
				// Refine location, gives crispier images
				vec3 iloc = start_loc + view_ray * (float(max_i) - relative_step_size* float(REFINEMENT_STEPS)/2.0);
				vec3 istep = view_ray / float(REFINEMENT_STEPS);
				for (int i=0; i<REFINEMENT_STEPS; i++) {
						max_val = max(max_val, sampleAs3DTextureRed(iloc));
						iloc += istep;
				}
				*/

				// Resolve final color
				gl_FragColor = vec4(max_val,0.0,0.0,1.0);
			}