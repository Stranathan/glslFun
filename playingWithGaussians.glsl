#define SEA_HEIGHT (-0.3)

float when_gt(float x, float y) 
{
  return max(sign(x - y), 0.0);
}

vec3 when_gt(vec3 x, vec3 y) 
{
  return max(sign(x - y), 0.0);
}

float when_lt(float x, float y) 
{
  return max(sign(y - x), 0.0);
}

float hash(vec2 p) {
    return fract(sin(p.x*100.+p.y*6574.)*5647.);
}

float smoothNoise(vec2 uv) 
{
    vec2 lv = fract(uv);
    vec2 id = floor(uv);
    
    lv = lv*lv*(3.-2.*lv);
    
    float bl = hash(id);
    float br = hash(id+vec2(1,0));
    float b = mix(bl, br, lv.x);
    
    float tl = hash(id+vec2(0,1));
    float tr = hash(id+vec2(1,1));
    float t = mix(tl, tr, lv.x);
    
    return mix(b, t, lv.y);
}

float valueNoise(vec2 uv) 
{
    float c = smoothNoise(uv*4.);
    
    // don't make octaves exactly twice as small
    // this way the pattern will look more random and repeat less
    c += smoothNoise(uv*8.2)*.5;
    c += smoothNoise(uv*16.7)*.25;
    c += smoothNoise(uv*32.4)*.125;
    c += smoothNoise(uv*64.5)*.0625;
    
    c /= 2.;
    
    return c;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
  
    //------------- uvs ------------- 
    vec2 gaussianUV = 2. * fragCoord/iResolution.xy - 1.;
    vec2 mousePos = 2. * iMouse.xy/iResolution.xy - 1.;
	vec2 noiseUV1 = 2. * fragCoord/iResolution.xy - 1.;
    vec2 noiseUV2 = 2. * fragCoord/iResolution.xy - 1.;
    vec2 uv = fragCoord/iResolution.xy;

    //------------- Crepuscular Rays ---------
    // normalize + center @ pos + account for aspect ratio
    vec2 lightPos = vec2(1., 3.5);
    vec2 uvCrepuscular = (fragCoord - lightPos * iResolution.xy ) / iResolution.y;
    
	// for drop off
    float radius = length(uvCrepuscular);
 	
    // light ray time seeds
    float seedA1 = 36.; 
	float seedB1 = 110.; 
    float seedA2 = 100.; 
	float seedB2 = 18.;
    
    float speed = .3;
   
    float angle = atan(uvCrepuscular.y/ uvCrepuscular.x);
    float twoRays1 = clamp( sin(1. * angle * seedA1 + iTime * speed) +
		cos(angle * seedB1 + iTime * speed),
		0., 1.);
    
    float twoRays2 = clamp( sin(1. * angle * seedA2 - iTime * speed) -
		cos(angle * seedB2 - iTime * .4 * speed),
		0., 1.);
    
    // drop off
    float dd = 2./(radius*radius);
    float rayMask = (twoRays1 + twoRays2 -.5)*dd;
 
    // ------------- noise -------------
    noiseUV1.xy -= 0.015 * iTime;
    noiseUV2.y -= 0.03 * iTime;
    float noise = valueNoise(4. * noiseUV1);
	float noise2 = valueNoise(2. * noiseUV2);
    float blizzNoise = noise * noise2 * 2.;
    vec3 snellCol = floor(3.1 * blizzNoise) * sin(2.2 * blizzNoise) * vec3(0.2, 0.6, 0.8);
    
    
    // ------------- Wave Function -------------
    float gaussian = 0.8 *  exp(-20. * pow((gaussianUV.x - mousePos.x), 2.0)) + (SEA_HEIGHT) + 0.03 * sin(iTime);
    
    // ------------- Masks -------------
    float snellMaskCut = 1. - (10. * gaussian + 3. * noise);
    float waveProfileMask = 1. - smoothstep(gaussian, gaussian + 0.01, gaussianUV.y);
    float snellMask = when_gt(gaussianUV.y, SEA_HEIGHT - 0.2 * noise) * (waveProfileMask * snellMaskCut) - 1.2;
    
    // ------------- Putting stuff together -------------
    snellMask *= when_gt(snellMask, 0.0); // clearing negative artifacts
    snellCol *=  snellMask * (1. +  10. * rayMask);
    snellCol = mix(snellCol, waveProfileMask * vec3(0.2, 0.6, 0.8), smoothstep(SEA_HEIGHT, 0.2, gaussianUV.y));
    vec3 seaCol = vec3(0.2, 0.6, 0.8) * (1. +  2. * rayMask);
    vec3 col = mix(seaCol, snellCol, smoothstep(-1., SEA_HEIGHT, gaussianUV.y));
    
    // correcting the dark gap after not having looked at this shader in a long time
    col += (waveProfileMask * vec3(0.2, 0.6, 0.8) * uv.y);
    
    fragColor = vec4(col, 1.0);
}