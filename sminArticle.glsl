#define SCALE (2.)
#define PI (3.14159)

float graph(float tolerance, float function, float axis)
{
    return (smoothstep(function, function + tolerance, axis))
         - (smoothstep(function + tolerance, function + 2. * tolerance, axis));
}

float derivativeEasingFunction(float minTolerance, float maxTolerance,
                               float maxDerivVal, float derivativeVal)
{
    return ((maxTolerance - minTolerance) * (1. - cos(PI * derivativeVal/ maxDerivVal)) + minTolerance);
}

float when_gt(float x, float y) 
{
  return max(sign(x - y), 0.0);
}

float when_lt(float x, float y) 
{
  return max(sign(y - x), 0.0);
}

float when_ge(float x, float y) 
{
  return 1.0 - when_lt(x, y);
}

float when_le(float x, float y) 
{
  return 1.0 - when_gt(x, y);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = SCALE * ( 2. * fragCoord/iResolution.xy - 1.);
	uv.x *= iResolution.x / iResolution.y;
    
    // abitrarily chosen to look nice
    float minEpsilon = 0.03;
    float maxEpsilon = 1.6 * minEpsilon;
    
    // sin(x)
    float periodNum = 3.;
    float amplitude = 1.;
    float sinusoid = amplitude * sin(periodNum * uv.x - 0.5 * iTime);
    float derivativeSinusoid = periodNum *  amplitude * cos(periodNum * uv.x - 0.5 * iTime);
    float maxDerivSinusoid = periodNum *  amplitude;
    
    // e^-x
    float exponential = exp(-uv.x);
    float derivativeExponential = -exp(-uv.x);
    float maxDerivExponential = -exp(0.73); // chosen with helper line -- max visible f(x)
    
    // smin
    float kk = 0.5;
	float dd = sinusoid - exponential;
    float ll = clamp(0.5 + dd / (2. * kk), 0.0, 1.0 );
    float dlldx = clamp((derivativeSinusoid - derivativeExponential)/ (2. * kk), 0.0, 1.0 );
    float leSmin = (1. - ll) * sinusoid +  ll * exponential - kk * ll * (1.0 - ll);
    float derivativeXi = dlldx * (-dd) + derivativeSinusoid * (1. - ll) 
        				   + derivativeExponential * ll - dlldx * kk + dlldx * 2. * kk * ll;
    float derivativeLeSmin = derivativeXi * when_gt(dd, -kk) + derivativeSinusoid * when_le(dd, -kk);
    
    // mask for background and making things lighter
    float mask = length(0.2 * uv);
    vec3 col = (1. - mask) * vec3(.129, .141, .176);
    
    // graphs
    float graphLeSmin = graph(derivativeEasingFunction(minEpsilon, maxEpsilon, maxDerivSinusoid, derivativeLeSmin),
                         leSmin, uv.y);
    float graphSinusoid = graph(derivativeEasingFunction(minEpsilon, maxEpsilon, maxDerivSinusoid, derivativeSinusoid),
                         sinusoid, uv.y);
    float graphExponential = graph(derivativeEasingFunction(minEpsilon, maxEpsilon, maxDerivExponential, derivativeExponential),
                         exponential, uv.y);
    
    // making "draw order"
    graphSinusoid *= (.6 - graphLeSmin);
    graphExponential *= (.5 - graphSinusoid) * (1. - graphLeSmin);
    
    // col and frag
    col += vec3(0., 0., 1.) * graphSinusoid + vec3(1., 0., 0.) * graphExponential + vec3(0., 1., 0.) * graphLeSmin;
    fragColor = vec4(col,1.0);
}