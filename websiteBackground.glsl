#define RAYMARCH_STEPS 70
#define MIN_DIST .001

float sdSphere( vec3 p, float s )
{
  return length(p)-s;
}

float map(vec3 p)
{
    vec3 q = mod(p + 1.0, 2.) - 1.0;
    return sdSphere(q, .2);
}

float raymarch(vec3 ro, vec3 rd)
{
	float t = 0.0;
    
    for(int i = 0; i < RAYMARCH_STEPS; ++i)
    {
        vec3 p = ro + rd * t; 
    	float d = map(p);
        
        if (d < MIN_DIST){
        	break;
        }
        
        t += min(d, 1.0);
    }
    return t;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = (fragCoord - 0.5 * iResolution.xy)/iResolution.y;
    
    vec3 ro = vec3(0., 1., 0.) - vec3(.0, 0., iTime);
	
    // zoinks
    // vec3 rd = normalize(vec3(uv,0.) - (ro - iTime));
    vec3 rd = normalize(vec3(uv, 2.));
    float dist = raymarch(ro, rd);
    
    float fog = 1.0 / (0.3 + dist * dist * 0.002);
    
    fog = clamp(fog, 0., 1.);
    fragColor = vec4(fog * vec3(0.43, 0.50, 0.56),1.0);
}