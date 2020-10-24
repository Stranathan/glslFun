#define SCALE (1.)
#define PI (3.14159)

float when_eq(float x, float y) 
{
  return 1.0 - abs(sign(x - y));
}

float when_neq(float x, float y)
{
  return abs(sign(x - y));
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

float smin( float a, float b, float k )
{
    float h = clamp( 0.5+0.5*(b-a)/k, 0.0, 1.0 );
    return mix( b, a, h ) - k*h*(1.0-h);
}

float normalizeOnRange(float a, float b, float x)
{
    return (b - x) / (b - a);
}

vec2 sphereGeometric(vec3 ro, vec3 rd, vec4 ss)
{
    float projLen = dot(ss.xyz - ro, rd);
    vec3 xi = ss.xyz - ro - projLen * rd;
    float xiLen = length(xi);
    
    vec2 intersectDistances = vec2(0.);
    
    if(xiLen < ss.w)
    {
        float lambda = sqrt(ss.w * ss.w - xiLen * xiLen);
        intersectDistances = vec2(projLen + lambda, projLen - lambda);
    }
    
    return intersectDistances;
}
vec2 sphereAlgebraic(vec3 ro, vec3 rd, vec4 ss)
{
    float a = 1.;
    float b = dot(ro - ss.xyz, rd);
    float ro2sphere = length(ro - ss.xyz);
    float c = ro2sphere * ro2sphere - ss.w * ss.w;
    
    vec2 intersectDistances;
    float discriminant = sqrt(b * b - c);
    // complex solutions --> no intersection
    if(discriminant < 0.)
    {
        intersectDistances = vec2(0., 0.);
    }
    
    intersectDistances = vec2(-b + discriminant, -b - discriminant);
    return intersectDistances;
}

float lineSegment(vec3 ro, vec3 rd, vec3 a, vec3 b)
{
    vec3 u = normalize(b - a);
    
    float dotProd1 = dot(u, a - ro);
    float dotProd2 = dot(rd, u);
    float dotProd3 = dot(rd, a - ro);
    
    float len = (dotProd1 - dotProd2 * dotProd3) / (dotProd2 * dotProd2 - 1.);
    len= clamp(len, 0.0 , length(b - a));
    
    vec3 p = a + u * len;
    
   	return length(cross(p-ro, rd));
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = SCALE * ( 2. * fragCoord/iResolution.xy - 1.);
    uv.x *= iResolution.x / iResolution.y;

    vec2 mousePos = SCALE * (2. * iMouse.xy/iResolution.xy - 1.);
    mousePos.x *= iResolution.x/ iResolution.y;
	
    // ray setup
    vec3 uv3d = vec3(uv, 0.);
    vec3 ro = vec3(0., 0., 2.);
    vec3 ray = uv3d - ro;
    vec3 rd = normalize(ray);

    // ray sphere intersection stuff
  	vec4 sphere = vec4(0., 0., -5, 2.);
    vec2 intersectionDistances = sphereGeometric(ro, rd, sphere);
    //vec2 intersectionDistances = sphereAlgebraic(ro, rd, sphere);
    
     // normalization
    float ro2sphere = length(sphere.xyz - ro); // shortest length
    float roTangent = sqrt(ro2sphere * ro2sphere - sphere.w * sphere.w); // longest length
    float normalizedIntersectionDistances = 
    clamp(when_gt(intersectionDistances.x, 0.) 
          * normalizeOnRange(ro2sphere - sphere.w, roTangent, intersectionDistances.y), 0., 1.);
    
    // line segment stuff
	vec3 a = vec3(2. * mousePos.x, 2. * mousePos.y, sphere.z + 2.);
	vec3 b = sphere.xyz;
	vec3 abDir = normalize(b - a);

	vec2 lineSegmentIntersectionPoints = sphereGeometric(a, abDir, sphere);

	float lineSegmentFrontHalf = lineSegment(ro, rd, a, a + abDir * lineSegmentIntersectionPoints.y);
	lineSegmentFrontHalf = clamp(30. * lineSegmentFrontHalf, 0., 1.);

	// to mask line segment behind sphere
	float mask = clamp(1. - 25. * normalizedIntersectionDistances, 0., 1.);
	float lineSegmentBackHalf = (1. - mask) + mask * lineSegment(ro, rd, a + abDir * lineSegmentIntersectionPoints.x, a + normalize(b - a) * 10. * lineSegmentIntersectionPoints.y);
	lineSegmentBackHalf = clamp(30. * lineSegmentBackHalf, 0., 1.);

	vec3 col =  (1. - lineSegmentFrontHalf) * vec3(.95, .2, .88) + (1. - lineSegmentBackHalf) * vec3(.95, .2, .88) + vec3(lineSegmentFrontHalf * lineSegmentBackHalf * normalizedIntersectionDistances);

	fragColor = vec4(vec3(col), 1.0);
}