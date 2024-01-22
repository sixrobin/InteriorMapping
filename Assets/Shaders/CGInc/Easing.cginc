float InBack(float t)
{
	return t * t * (2.70158 * t - 1.70158);
}
float OutBack(float t)
{
	return 1.0 + (t - 1.0) * (t - 1.0) * (2.70158 * (t - 1.0) + 1.70158);
}
float InOutBack(float t)
{
	return t < 0.5 ? 0.5 * (4.0 * t * t * (3.595 * (t * 2.0) - 2.595)) : 0.5 * ((t * 2.0 - 2.0) * (t * 2.0 - 2.0) * (3.595 * (t * 2.0 - 2.0) + 2.595) + 2.0);
}

float OutBounce(float t)
{
	if (t < 1.0 / 2.75)
		return 7.5625 * t * t;
	if (t < 2.0 / 2.75)
		return 7.5625 * (t - 1.5 / 2.75) * (t - 1.5 / 2.75) + 0.75;
	if (t < 2.5 / 2.75)
		return 7.5625 * (t - 2.25 / 2.75) * (t - 2.25 / 2.75) + 0.9375;
	return 7.5625 * (t - 2.625 / 2.75) * (t - 2.625 / 2.75) + 0.984375;
}
float InBounce(float t)
{
	return 1.0 - OutBounce(1.0 - t);
}
float InOutBounce(float t)
{
	return t < 0.5 ? InBounce(t * 2.0) * 0.5 : OutBounce(t * 2.0 - 1.0) * 0.5 + 0.5;
}

float InCirc(float t)
{
	return -(float)(sqrt(1.0 - t * t) - 1.0);
}
float OutCirc(float t)
{
	return sqrt(1.0 - (t * t - 2.0 * t + 1.0));
}
float InOutCirc(float t)
{
	return t < 0.5 ? -0.5 * ((float)sqrt(1.0 - 4.0 * t * t) - 1.0) : 0.5 * ((float)sqrt(1.0 - (4.0 * t * t - 8.0 * t + 4.0)) + 1.0);
}

float InCubic(float t)
{
	return t * t * t;
}
float OutCubic(float t)
{
	return --t * t * t + 1.0;
}
float InOutCubic(float t)
{
	return t < 0.5 ? 4.0 * t * t * t : (t - 1.0) * (4.0 * t * t - 8.0 * t + 4.0) + 1.0;
}

float InElastic(float t)
{
	if (t == 0.0 || t == 1.0)
		return t;
	return -(float)(pow(2.0, 10.0 * (t -= 1.0)) * sin((t * 1.0 - 0.075) * (2.0 * 3.1416) / 0.3));
}
float OutElastic(float t)
{
	if (t == 0 || t == 1.0)
		return t;
	return pow(2.0, -10.0 * t) * sin((t - 0.075) * 2.0 * 3.1416 / 0.3) + 1.0;
}
float InOutElastic(float t)
{
	if (t == 0 || (t /= 0.5) == 2.0)
		return t;
	return t < 1.0 ? -0.5 * (float)(pow(2.0, 10.0 * --t) * sin((t - 0.075) * 2.0 * 3.1416 / 0.3)) : (float)(pow(2.0, -10.0 * --t) * sin((t - 0.075) * 2.0 * 3.1416 / 0.3) * 0.5 + 1.0);
}

float InExpo(float t)
{
	return pow(2.0, 10.0 * (t - 1.0));
}
float OutExpo(float t)
{
	return -(float)pow(2.0, -10.0 * t) + 1.0;
}
float InOutExpo(float t)
{
	return t < 0.5 ? 0.5 * (float)pow(2.0, 10.0 * (t * 2.0 - 1.0)) : 0.5 * (-(float)pow(2.0, -10.0 * (t * 2.0 - 1.0)) + 2.0);
}

float InQuad(float t)
{
	return t * t;
}
float OutQuad(float t)
{
	return t * (2.0 - t);
}
float InOutQuad(float t)
{
	return t < 0.5 ? 2.0 * t * t : (4.0 - 2.0 * t) * t - 1.0;
}

float InQuart(float t)
{
	return t * t * t * t;
}
float OutQuart(float t)
{
	return 1.0 - (--t) * t * t * t;
}
float InOutQuart(float t)
{
	return t < 0.5 ? 8.0 * t * t * t * t : 1.0 - 8.0 * --t * t * t * t;
}

float InQuint(float t)
{
	return t * t * t * t * t;
}
float OutQuint(float t)
{
	return --t * t * t * t * t + 1.0;
}
float InOutQuint(float t)
{
	return t < 0.5 ? 16.0 * t * t * t * t * t : 16.0 * --t * t * t * t * t + 1.0;
}

float InSine(float t)
{
	return -(float)cos(t * (3.1416 / 2.0)) + 1.0;
}
float OutSine(float t)
{
	return sin(t * (3.1416 / 2.0));
}
float InOutSine(float t)
{
	return -0.5 * (float)(cos(3.1416 * t) - 1.0);
}