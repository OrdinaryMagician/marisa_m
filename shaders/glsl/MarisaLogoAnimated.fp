// animated CHILD OF ASH logo

#define hardlight(a,b) (2*a<1.0)?clamp(2.0*a*b,0.0,1.0):clamp(1.0-2.0*(1.0-b)*(1.0-a),0.0,1.0)
const float pi = 3.14159265358979323846;

vec2 warpcoord( in vec2 uv )
{
	vec2 offset;
	offset.y = sin(pi*2.*(uv.x*4.+timer*.25))*.01;
	offset.y += timer*.1;
	offset.x = cos(pi*2.*(uv.y*2.+timer*.25))*.01;
	offset.x += timer*.025;
	return fract(uv+offset);
}
vec2 warpcoord2( in vec2 uv )
{
	vec2 offset;
	offset.y = sin(pi*2.*(uv.x*4.+timer*.25))*.01;
	offset.y += timer*.1;
	offset.x = cos(pi*2.*(uv.y*2.+timer*.25))*.01;
	offset.x += timer*.025;
	return fract(uv*vec2(-.5,.5)+offset);
}

// based on gimp color to alpha, but simplified
vec4 blacktoalpha( in vec4 src )
{
	vec4 dst = src;
	float alpha = 0.;
	float a;
	a = clamp(dst.r,0.,1.);
	if ( a > alpha ) alpha = a;
	a = clamp(dst.g,0.,1.);
	if ( a > alpha ) alpha = a;
	a = clamp(dst.b,0.,1.);
	if ( a > alpha ) alpha = a;
	if ( alpha > 0. )
	{
		float ainv = 1./alpha;
		dst.rgb *= ainv;
	}
	dst.a *= alpha;
	return dst;
}
#ifdef NO_BILINEAR
#define BilinearSample(x,y,z,w) texture(x,y)
#else
vec4 BilinearSample( in sampler2D tex, in vec2 pos, in vec2 size, in vec2 pxsize )
{
	vec2 f = fract(pos*size);
	pos += (.5-f)*pxsize;
	vec4 p0q0 = texture(tex,pos);
	vec4 p1q0 = texture(tex,pos+vec2(pxsize.x,0));
	vec4 p0q1 = texture(tex,pos+vec2(0,pxsize.y));
	vec4 p1q1 = texture(tex,pos+vec2(pxsize.x,pxsize.y));
	vec4 pInterp_q0 = mix(p0q0,p1q0,f.x);
	vec4 pInterp_q1 = mix(p0q1,p1q1,f.x);
	return mix(pInterp_q0,pInterp_q1,f.y);
}
#endif

void SetupMaterial( inout Material mat )
{
	// store these to save some time
	vec2 size = vec2(textureSize(Layer1,0));
	vec2 pxsize = 1./size;
	// y'all ready for this multilayered madness?
	vec2 uv = vTexCoord.st;
	// base first layer
	vec4 base = BilinearSample(Layer1,uv,size,pxsize);
	// second layer, add two warps of red at
	vec4 tmp;
	tmp.r = BilinearSample(Layer2,warpcoord(uv),size,pxsize).x;
	tmp.r += BilinearSample(Layer2,warpcoord2(uv),size,pxsize).x;
	tmp.r *= .25;
	// second layer, hard light green
	tmp.g = BilinearSample(Layer2,uv,size,pxsize).y;
	tmp.r = hardlight(tmp.g,tmp.r);
	tmp.gb = tmp.rr;
	tmp.a = 1.;
	// color to alpha
	tmp = blacktoalpha(tmp);
	tmp.rgb = vec3(.5);
	// first layer, multiply alpha using second layer blue
	vec4 tmp2;
	tmp2.r = pow(BilinearSample(Layer2,uv,size,pxsize).z,4.)-1.;
	tmp2.r += texture(fadetex,vec2(.5)).x*2.;
	base.a *= clamp(tmp2.r,0.,1.);
	// second layer, fade in
	tmp2.r = texture(fadetex,vec2(.5)).y;
	tmp *= tmp2.r;
	// alpha blend onto first layer
	tmp2.a = tmp.a+base.a;
	tmp2.rgb = (tmp.rgb*tmp.a+base.rgb*base.a*(1.-tmp.a))/tmp2.a;
	if ( tmp2.a == 0. ) tmp2.rgb = vec3(0.);
	base = tmp2;
	// clamp
	base = clamp(base,vec4(0.),vec4(1.));
	// ding, logo's done
	mat.Base = base;
}
