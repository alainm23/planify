/* gsl.vapi
 *
 * Copyright (C) 2008  Matias De la Puente
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.

 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.

 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301  USA
 *
 * Author:
 * 	Matias De la Puente <mfpuente.ar@gmail.com>
 */

namespace Gsl
{
	/*
	 * Physical Constants
	 */
	[CCode (cprefix="GSL_CONST_NUM_", cheader_filename="gsl/gsl_const_num.h", has_type_id = false)]
	public enum ConstNum
	{
		FINE_STRUCTURE,
		AVOGADRO,
		YOTTA,
		ZETTA,
		EXA,
		PETA,
		TERA,
		GIGA,
		MEGA,
		KILO,
		MILLI,
		MICRO,
		NANO,
		PICO,
		FEMTO,
		ATTO,
		ZEPTO,
		YOCTO
	}

	[CCode (cprefix="GSL_CONST_CGS_", cheader_filename="gsl/gsl_const_cgs.h", has_type_id = false)]
	public enum ConstCGS
	{
		SPEED_OF_LIGHT,
		GRAVITATIONAL_CONSTANT,
		PLANCKS_CONSTANT_H,
		PLANCKS_CONSTANT_HBAR,
		ASTRONOMICAL_UNIT,
		LIGHT_YEAR,
		PARSEC,
		GRAV_ACCEL,
		ELECTRON_VOLT,
		MASS_ELECTRON,
		MASS_MUON,
		MASS_PROTON,
		MASS_NEUTRON,
		RYDBERG,
		BOLTZMANN,
		BOHR_MAGNETON,
		NUCLEAR_MAGNETON,
		ELECTRON_MAGNETIC_MOMENT,
		PROTON_MAGNETIC_MOMENT,
		MOLAR_GAS,
		STANDARD_GAS_VOLUME,
		MINUTE,
		HOUR,
		DAY,
		WEEK,
		INCH,
		FOOT,
		YARD,
		MILE,
		NAUTICAL_MILE,
		FATHOM,
		MIL,
		POINT,
		TEXPOINT,
		MICRON,
		ANGSTROM,
		HECTARE,
		ACRE,
		BARN,
		LITER,
		US_GALLON,
		QUART,
		PINT,
		CUP,
		FLUID_OUNCE,
		TABLESPOON,
		TEASPOON,
		CANADIAN_GALLON,
		UK_GALLON,
		MILES_PER_HOUR,
		KILOMETERS_PER_HOUR,
		KNOT,
		POUND_MASS,
		OUNCE_MASS,
		TON,
		METRIC_TON,
		UK_TON,
		TROY_OUNCE,
		CARAT,
		UNIFIED_ATOMIC_MASS,
		GRAM_FORCE,
		POUND_FORCE,
		KILOPOUND_FORCE,
		POUNDAL,
		CALORIE,
		BTU,
		THERM,
		HORSEPOWER,
		BAR,
		STD_ATMOSPHERE,
		TORR,
		METER_OF_MERCURY,
		INCH_OF_MERCURY,
		INCH_OF_WATER,
		PSI,
		POISE,
		STOKES,
		FARADAY,
		ELECTRON_CHARGE,
		GAUSS,
		STILB,
		LUMEN,
		LUX,
		PHOT,
		FOOTCANDLE,
		LAMBERT,
		FOOTLAMBERT,
		CURIE,
		ROENTGEN,
		RAD,
		SOLAR_MASS,
		BOHR_RADIUS,
		NEWTON,
		DYNE,
		JOULE,
		ERG,
		STEFAN_BOLTZMANN_CONSTANT,
		THOMSON_CROSS_SECTION
	}

	[CCode (cprefix="GSL_CONST_CGSM_", cheader_filename="gsl/gsl_const_cgsm.h", has_type_id = false)]
	public enum ConstCGSM
	{
		SPEED_OF_LIGHT,
		GRAVITATIONAL_CONSTANT,
		PLANCKS_CONSTANT_H,
		PLANCKS_CONSTANT_HBAR,
		ASTRONOMICAL_UNIT,
		LIGHT_YEAR,
		PARSEC,
		GRAV_ACCEL,
		ELECTRON_VOLT,
		MASS_ELECTRON,
		MASS_MUON,
		MASS_PROTON,
		MASS_NEUTRON,
		RYDBERG,
		BOLTZMANN,
		BOHR_MAGNETON,
		NUCLEAR_MAGNETON,
		ELECTRON_MAGNETIC_MOMENT,
		PROTON_MAGNETIC_MOMENT,
		MOLAR_GAS,
		STANDARD_GAS_VOLUME,
		MINUTE,
		HOUR,
		DAY,
		WEEK,
		INCH,
		FOOT,
		YARD,
		MILE,
		NAUTICAL_MILE,
		FATHOM,
		MIL,
		POINT,
		TEXPOINT,
		MICRON,
		ANGSTROM,
		HECTARE,
		ACRE,
		BARN,
		LITER,
		US_GALLON,
		QUART,
		PINT,
		CUP,
		FLUID_OUNCE,
		TABLESPOON,
		TEASPOON,
		CANADIAN_GALLON,
		UK_GALLON,
		MILES_PER_HOUR,
		KILOMETERS_PER_HOUR,
		KNOT,
		POUND_MASS,
		OUNCE_MASS,
		TON,
		METRIC_TON,
		UK_TON,
		TROY_OUNCE,
		CARAT,
		UNIFIED_ATOMIC_MASS,
		GRAM_FORCE,
		POUND_FORCE,
		KILOPOUND_FORCE,
		POUNDAL,
		CALORIE,
		BTU,
		THERM,
		HORSEPOWER,
		BAR,
		STD_ATMOSPHERE,
		TORR,
		METER_OF_MERCURY,
		INCH_OF_MERCURY,
		INCH_OF_WATER,
		PSI,
		POISE,
		STOKES,
		FARADAY,
		ELECTRON_CHARGE,
		GAUSS,
		STILB,
		LUMEN,
		LUX,
		PHOT,
		FOOTCANDLE,
		LAMBERT,
		FOOTLAMBERT,
		CURIE,
		ROENTGEN,
		RAD,
		SOLAR_MASS,
		BOHR_RADIUS,
		NEWTON,
		DYNE,
		JOULE,
		ERG,
		STEFAN_BOLTZMANN_CONSTANT,
		THOMSON_CROSS_SECTION
	}

	[CCode (cprefix="GSL_CONST_MKS_", cheader_filename="gsl/gsl_const_mks.h", has_type_id = false)]
	public enum ConstMKS
	{
		SPEED_OF_LIGHT,
		GRAVITATIONAL_CONSTANT,
		PLANCKS_CONSTANT_H,
		PLANCKS_CONSTANT_HBAR,
		ASTRONOMICAL_UNIT,
		LIGHT_YEAR,
		PARSEC,
		GRAV_ACCEL,
		ELECTRON_VOLT,
		MASS_ELECTRON,
		MASS_MUON,
		MASS_PROTON,
		MASS_NEUTRON,
		RYDBERG,
		BOLTZMANN,
		BOHR_MAGNETON,
		NUCLEAR_MAGNETON,
		ELECTRON_MAGNETIC_MOMENT,
		PROTON_MAGNETIC_MOMENT,
		MOLAR_GAS,
		STANDARD_GAS_VOLUME,
		MINUTE,
		HOUR,
		DAY,
		WEEK,
		INCH,
		FOOT,
		YARD,
		MILE,
		NAUTICAL_MILE,
		FATHOM,
		MIL,
		POINT,
		TEXPOINT,
		MICRON,
		ANGSTROM,
		HECTARE,
		ACRE,
		BARN,
		LITER,
		US_GALLON,
		QUART,
		PINT,
		CUP,
		FLUID_OUNCE,
		TABLESPOON,
		TEASPOON,
		CANADIAN_GALLON,
		UK_GALLON,
		MILES_PER_HOUR,
		KILOMETERS_PER_HOUR,
		KNOT,
		POUND_MASS,
		OUNCE_MASS,
		TON,
		METRIC_TON,
		UK_TON,
		TROY_OUNCE,
		CARAT,
		UNIFIED_ATOMIC_MASS,
		GRAM_FORCE,
		POUND_FORCE,
		KILOPOUND_FORCE,
		POUNDAL,
		CALORIE,
		BTU,
		THERM,
		HORSEPOWER,
		BAR,
		STD_ATMOSPHERE,
		TORR,
		METER_OF_MERCURY,
		INCH_OF_MERCURY,
		INCH_OF_WATER,
		PSI,
		POISE,
		STOKES,
		FARADAY,
		ELECTRON_CHARGE,
		GAUSS,
		STILB,
		LUMEN,
		LUX,
		PHOT,
		FOOTCANDLE,
		LAMBERT,
		FOOTLAMBERT,
		CURIE,
		ROENTGEN,
		RAD,
		SOLAR_MASS,
		BOHR_RADIUS,
		NEWTON,
		DYNE,
		JOULE,
		ERG,
		STEFAN_BOLTZMANN_CONSTANT,
		THOMSON_CROSS_SECTION,
		VACUUM_PERMITTIVITY,
		VACUUM_PERMEABILITY,
		DEBYE
	}

	[CCode (cprefix="GSL_CONST_MKSA_", cheader_filename="gsl/gsl_const_mksa.h", has_type_id = false)]
	public enum ConstMKSA
	{
		SPEED_OF_LIGHT,
		GRAVITATIONAL_CONSTANT,
		PLANCKS_CONSTANT_H,
		PLANCKS_CONSTANT_HBAR,
		ASTRONOMICAL_UNIT,
		LIGHT_YEAR,
		PARSEC,
		GRAV_ACCEL,
		ELECTRON_VOLT,
		MASS_ELECTRON,
		MASS_MUON,
		MASS_PROTON,
		MASS_NEUTRON,
		RYDBERG,
		BOLTZMANN,
		BOHR_MAGNETON,
		NUCLEAR_MAGNETON,
		ELECTRON_MAGNETIC_MOMENT,
		PROTON_MAGNETIC_MOMENT,
		MOLAR_GAS,
		STANDARD_GAS_VOLUME,
		MINUTE,
		HOUR,
		DAY,
		WEEK,
		INCH,
		FOOT,
		YARD,
		MILE,
		NAUTICAL_MILE,
		FATHOM,
		MIL,
		POINT,
		TEXPOINT,
		MICRON,
		ANGSTROM,
		HECTARE,
		ACRE,
		BARN,
		LITER,
		US_GALLON,
		QUART,
		PINT,
		CUP,
		FLUID_OUNCE,
		TABLESPOON,
		TEASPOON,
		CANADIAN_GALLON,
		UK_GALLON,
		MILES_PER_HOUR,
		KILOMETERS_PER_HOUR,
		KNOT,
		POUND_MASS,
		OUNCE_MASS,
		TON,
		METRIC_TON,
		UK_TON,
		TROY_OUNCE,
		CARAT,
		UNIFIED_ATOMIC_MASS,
		GRAM_FORCE,
		POUND_FORCE,
		KILOPOUND_FORCE,
		POUNDAL,
		CALORIE,
		BTU,
		THERM,
		HORSEPOWER,
		BAR,
		STD_ATMOSPHERE,
		TORR,
		METER_OF_MERCURY,
		INCH_OF_MERCURY,
		INCH_OF_WATER,
		PSI,
		POISE,
		STOKES,
		FARADAY,
		ELECTRON_CHARGE,
		GAUSS,
		STILB,
		LUMEN,
		LUX,
		PHOT,
		FOOTCANDLE,
		LAMBERT,
		FOOTLAMBERT,
		CURIE,
		ROENTGEN,
		RAD,
		SOLAR_MASS,
		BOHR_RADIUS,
		NEWTON,
		DYNE,
		JOULE,
		ERG,
		STEFAN_BOLTZMANN_CONSTANT,
		THOMSON_CROSS_SECTION,
		VACUUM_PERMITTIVITY,
		VACUUM_PERMEABILITY,
		DEBYE
	}


	/*
	 * Error Handling
	 */
	[CCode (cprefix="GSL_", cheader_filename="gsl/gsl_errno.h", has_type_id = false)]
	public enum Status
	{
		SUCCESS,
		FAILURE,
		CONTINUE,
		EDOM,
		ERANGE,
		EFAULT,
		EINVAL,
		EFAILED,
		EFACTOR,
		ESANITY,
		ENOMEM,
		EBADFUNC,
		ERUNAWAY,
		EMAXITER,
		EZERODIV,
		EBADTOL,
		ETOL,
		EUNDRFLW,
		EOVRFLW,
		ELOSS,
		EROUND,
		EBADLEN,
		ENOTSQR,
		ESING,
		EDIVERGE,
		EUNSUP,
		EUNIMPL,
		ECACHE,
		ETABLE,
		ENOPROG,
		ENOPROGJ,
		ETOLF,
		ETOLX,
		ETOLG,
		EOF
	}

	[CCode (cprefix="GSL_PREC_", cheader_filename="gsl/gsl_mode.h", has_type_id = false)]
	public enum Mode
	{
		DOUBLE,
		SINGLE,
		APPROX
	}

	[CCode (has_target = false)]
	public delegate void ErrorHandler (string reason, string file, int line, int errno);
	[CCode (has_target = false)]
	public delegate void StreamHandler (string label, string file, int line, string reason);

	[CCode (lower_case_cprefix="gsl_", cheader_filename="gsl/gsl_errno.h")]
	namespace Error
	{
		public static void error (string reason, string file, int line, int errno);
		public static unowned string strerror (int errno);
		public static ErrorHandler set_error_handler (ErrorHandler? new_handler);
		public static ErrorHandler set_error_handler_off ();
	}

	[CCode (lower_case_cprefix="gsl_", cheader_filename="gsl/gsl_errno.h")]
	namespace Stream
	{
		[CCode (cname="gsl_stream_printf")]
		public static void printf (string label, string file, int line, string reason);
		public static StreamHandler set_stream_handler (StreamHandler new_handler);
		public static GLib.FileStream set_stream (GLib.FileStream new_stream);
	}


	/*
	 * Mathematical Functions
	 */
	[CCode (cprefix="", cheader_filename="gsl/gsl_math.h", has_type_id = false)]
	public enum MathConst
	{
		M_E,
		M_LOG2E,
		M_LOG10E,
		M_SQRT2,
		M_SQRT1_2,
		M_SQRT3,
		M_PI,
		M_PI_2,
		M_PI_4,
		M_2_SQRTPI,
		M_1_PI,
		M_2_PI,
		M_LN10,
		M_LN2,
		M_LNPI,
		M_EULER
	}

	/* The isnan, isinf and finite are define in the double type. The elementary functions are in GLib.Math */

	[CCode (has_target = false)]
	public delegate double _Function (double x, void* params);
	[CCode (has_target = false)]
	public delegate void _FunctionFdf (double x, void* params, out double f, out double df);

	[SimpleType]
	[CCode (cname="gsl_function", cheader_filename="gsl/gsl_math.h", has_type_id = false)]
	public struct Function
	{
		public _Function function;
		public void* params;
	}

	[SimpleType]
	[CCode (cname="gsl_function_fdf", cheader_filename="gsl/gsl_math.h", has_type_id = false)]
	public struct FunctionFdf
	{
		public _Function f;
		public _Function df;
		public _FunctionFdf fdf;
		public void* params;
	}


	/*
	 * Complex Numbers
	 */
	[SimpleType]
	[CCode (cname="gsl_complex", cheader_filename="gsl/gsl_complex.h,gsl/gsl_complex_math.h", has_type_id = false)]
	public struct Complex
	{
		[CCode (cname="dat[0]")]
		public double real;
		[CCode (cname="dat[1]")]
		public double imag;
		public static Complex rect (double x, double y);
		public static Complex polar (double r, double theta);

		public static double arg (Complex z);
		public static double abs (Complex z);
		public static double abs2 (Complex z);
		public static double logabs (Complex z);

		public static Complex add (Complex a, Complex b);
		public static Complex sub (Complex a, Complex b);
		public static Complex mul (Complex a, Complex b);
		public static Complex div (Complex a, Complex b);
		public static Complex add_real (Complex a, double x);
		public static Complex sub_real (Complex a, double x);
		public static Complex mul_real (Complex a, double x);
		public static Complex div_real (Complex a, double x);
		public static Complex add_imag (Complex a, double y);
		public static Complex sub_imag (Complex a, double y);
		public static Complex mul_imag (Complex a, double y);
		public static Complex div_imag (Complex a, double y);
		public static Complex conjugate (Complex z);
		public static Complex inverse (Complex z);
		public static Complex negative (Complex z);

		public static Complex sqrt (Complex z);
		public static Complex sqrt_real (double x);
		public static Complex pow (Complex z, Complex a);
		public static Complex pow_real (Complex z, double x);
		public static Complex exp (Complex z);
		public static Complex log (Complex z);
		public static Complex log10 (Complex z);
		public static Complex log_b (Complex z, Complex b);

		public static Complex sin (Complex z);
		public static Complex cos (Complex z);
		public static Complex tan (Complex z);
		public static Complex sec (Complex z);
		public static Complex csc (Complex z);
		public static Complex cot (Complex z);

		public static Complex arcsin (Complex z);
		public static Complex arcsin_real (double z);
		public static Complex arccos (Complex z);
		public static Complex arccos_real (double z);
		public static Complex arctan (Complex z);
		public static Complex arcsec (Complex z);
		public static Complex arcsec_real (double z);
		public static Complex arccsc (Complex z);
		public static Complex arccsc_real (double z);
		public static Complex arccot (Complex z);

		public static Complex sinh (Complex z);
		public static Complex cosh (Complex z);
		public static Complex tanh (Complex z);
		public static Complex sech (Complex z);
		public static Complex csch (Complex z);
		public static Complex coth (Complex z);

		public static Complex arcsinh (Complex z);
		public static Complex arccosh (Complex z);
		public static Complex arccosh_real (double z);
		public static Complex arctanh (Complex z);
		public static Complex arctanh_real (double z);
		public static Complex arcsech (Complex z);
		public static Complex arccsch (Complex z);
		public static Complex arccoth (Complex z);
	}


	/*
	 * Polynomials
	 */
	[CCode (lower_case_cprefix="gsl_poly_", cheader_filename="gsl/gsl_poly.h")]
	namespace Poly
	{
		public static double eval (double[] c, double x);
		public static Complex complex_eval (double[] c, Complex z);
		[CCode (cname="gsl_complex_poly_complex_eval")]
		public static Complex poly_complex_eval (Complex[] c, Complex z);

		public static int dd_init ([CCode (array_length = false)] double[] dd, [CCode (array_length = false)] double[] xa, [CCode (array_length = false)] double[] ya, size_t size);
		public static double dd_eval ([CCode (array_length = false)] double[] dd, [CCode (array_length = false)] double[] xa, size_t size, double x);
		public static int dd_taylor ([CCode (array_length = false)] double[] c, double xp, [CCode (array_length = false)] double[] dd, [CCode (array_length = false)] double[] xa, size_t size, [CCode (array_length = false)] double[] w);

		public static int solve_quadratic (double a, double b, double c, out double x0, out double x1);
		public static int complex_solve_quadratic (double a, double b, double c, out Complex z0, out Complex z1);

		public static int solve_cubic (double a, double b, double c, out double x0, out double x1, out double x2);
		public static int complex_solve_cubic (double a, double b, double c, out Complex z0, out Complex z1, out Complex z2);
	}

	[Compact]
	[CCode (cname="gsl_poly_complex_workspace", cheader_filename="gsl/gsl_poly.h")]
	public class PolyComplexWorkspace
	{
		public size_t nc;
		public double* matrix;

		[CCode (cname="gsl_poly_complex_workspace_alloc")]
		public PolyComplexWorkspace (size_t n);
		[CCode (cname="gsl_poly_complex_solve")]
		public static int solve (double[]a, PolyComplexWorkspace w, out double z);
	}


	/*
	 * Special Functions
	 */
	[SimpleType]
	[CCode (cname="gsl_sf_result", cheader_filename="gsl/gsl_sf_result.h", has_type_id = false)]
	public struct Result
	{
		public double val;
		public double err;
	}

	[SimpleType]
	[CCode (cname="gsl_sf_result_e10", cheader_filename="gsl/gsl_sf_result.h", has_type_id = false)]
	public struct ResultE10
	{
		public double val;
		public double err;
		public int e10;
	}

	[CCode (lower_case_cprefix="gsl_sf_airy_", cheader_filename="gsl/gsl_sf_airy.h")]
	namespace Airy
	{
		public static double Ai (double x, Mode mode);
		public static int Ai_e (double x, Mode mode, out Result result);
		public static double Bi (double x, Mode mode);
		public static int Bi_e (double x, Mode mode, out Result result);
		public static double Ai_scaled (double x, Mode mode);
		public static int Ai_scaled_e (double x, Mode mode, out Result result);
		public static double Bi_scaled (double x, Mode mode);
		public static int Bi_scaled_e (double x, Mode mode, out Result result);

		public static double Ai_deriv (double x, Mode mode);
		public static int Ai_deriv_e (double x, Mode mode, out Result result);
		public static double Bi_deriv (double x, Mode mode);
		public static int Bi_deriv_e (double x, Mode mode, out Result result);
		public static double Ai_deriv_scaled (double x, Mode mode);
		public static int Ai_deriv_scaled_e (double x, Mode mode, out Result result);
		public static double Bi_deriv_scaled (double x, Mode mode);
		public static int Bi_deriv_scaled_e (double x, Mode mode, out Result result);

		public static double zero_Ai (uint s);
		public static int zero_Ai_e (uint s, out Result result);
		public static double zero_Bi (uint s);
		public static int zero_Bi_e (uint s, out Result result);

		public static double zero_Ai_deriv (uint s);
		public static int zero_Ai_deriv_e (uint s, out Result result);
		public static double zero_Bi_deriv (uint s);
		public static int zero_Bi_deriv_e (uint s, out Result result);
	}

	[CCode (lower_case_cprefix="gsl_sf_bessel_", cheader_filename="gsl/gsl_sf_bessel.h")]
	namespace Bessel
	{
		public static double J0 (double x);
		public static int J0_e (double x, out Result result);
		public static double J1 (double x);
		public static int J1_e (double x, out Result result);
		public static double Jn (int n, double x);
		public static int Jn_e (int n, double x, out Result result);
		public static int Jn_array (int nmin, int nmax, double x, [CCode (array_length = false)] double[] result_array);

		public static double Y0 (double x);
		public static int Y0_e (double x, out Result result);
		public static double Y1 (double x);
		public static int Y1_e (double x, out Result result);
		public static double Yn (int n, double x);
		public static int Yn_e (int n, double x, out Result result);
		public static int Yn_array (int nmin, int nmax, double x, [CCode (array_length = false)] double[] result_array);

		public static double I0 (double x);
		public static int I0_e (double x, out Result result);
		public static double I1 (double x);
		public static int I1_e (double x, out Result result);
		public static double In (int n, double x);
		public static int In_e (int n, double x, out Result result);
		public static int In_array (int nmin, int nmax, double x, [CCode (array_length = false)] double[] result_array);
		public static double I0_scaled (double x);
		public static int I0_scaled_e (double x, out Result result);
		public static double I1_scaled (double x);
		public static int I1_scaled_e (double x, out Result result);
		public static double In_scaled (int n, double x);
		public static int In_scaled_e (int n, double x, out Result result);
		public static int In_scaled_array (int nmin, int nmax, double x, [CCode (array_length = false)] double[] result_array);

		public static double K0 (double x);
		public static int K0_e (double x, out Result result);
		public static double K1 (double x);
		public static int K1_e (double x, out Result result);
		public static double Kn (int n, double x);
		public static int Kn_e (int n, double x, out Result result);
		public static int Kn_array (int nmin, int nmax, double x, [CCode (array_length = false)] double[] result_array);
		public static double K0_scaled (double x);
		public static int K0_scaled_e (double x, out Result result);
		public static double K1_scaled (double x);
		public static int K1_scaled_e (double x, out Result result);
		public static double Kn_scaled (int n, double x);
		public static int Kn_scaled_e (int n, double x, out Result result);
		public static int Kn_scaled_array (int nmin, int nmax, double x, [CCode (array_length = false)] double[] result_array);

		public static double j0 (double x);
		public static int j0_e (double x, out Result result);
		public static double j1 (double x);
		public static int j1_e (double x, out Result result);
		public static double j2 (double x);
		public static int j2_e (double x, out Result result);
		public static double jl (int l, double x);
		public static int jl_e (int l, double x, out Result result);
		public static int jl_array (int lmax, double x, [CCode (array_length = false)] double[] result_array);
		public static int jl_steed_array (int lmax, double x, [CCode (array_length = false)] double[] jl_x_array);

		public static double y0 (double x);
		public static int y0_e (double x, out Result result);
		public static double y1 (double x);
		public static int y1_e (double x, out Result result);
		public static double y2 (double x);
		public static int y2_e (double x, out Result result);
		public static double yl (int l, double x);
		public static int yl_e (int l, double x, out Result result);
		public static int yl_array (int lmax, double x, [CCode (array_length = false)] double[] result_array);

		public static double i0_scaled (double x);
		public static int i0_scaled_e (double x, out Result result);
		public static double i1_scaled (double x);
		public static int i1_scaled_e (double x, out Result result);
		public static double i2_scaled (double x);
		public static int i2_scaled_e (double x, out Result result);
		public static double il_scaled (int l, double x);
		public static int il_scaled_e (int l, double x, out Result result);
		public static int il_scaled_array (int lmax, double x, [CCode (array_length = false)] double[] result_array);

		public static double k0_scaled (double x);
		public static int k0_scaled_e (double x, out Result result);
		public static double k1_scaled (double x);
		public static int k1_scaled_e (double x, out Result result);
		public static double k2_scaled (double x);
		public static int k2_scaled_e (double x, out Result result);
		public static double kl_scaled (int l, double x);
		public static int kl_scaled_e (int l, double x, out Result result);
		public static int kl_scaled_array (int lmax, double x, [CCode (array_length = false)] double[] result_array);

		public static double Jnu (double nu, double x);
		public static int Jnu_e (double nu, double x, out Result result);
		public static int sequence_Jnu_e (double nu, Mode mode, size_t size, [CCode (array_length = false)] double[] v);

		public static double Ynu (double nu, double x);
		public static int Ynu_e (double nu, double x, out Result result);

		public static double Inu (double nu, double x);
		public static int Inu_e (double nu, double x, out Result result);
		public static double Inu_scaled (double nu, double x);
		public static int Inu_scaled_e (double nu, double x, out Result result);

		public static double Knu (double nu, double x);
		public static int Knu_e (double nu, double x, out Result result);
		public static double lnKnu (double nu, double x);
		public static int lnKnu_e (double nu, double x, out Result result);
		public static double Knu_scaled (double nu, double x);
		public static int Knu_scaled_e (double nu, double x, out Result result);

		public static double zero_J0 (uint s);
		public static int zero_J0_e (uint s, out Result result);
		public static double zero_J1 (uint s);
		public static int zero_J1_e (uint s, out Result result);
		public static double zero_Jnu (double nu, uint s);
		public static int zero_Jnu_e (double nu, uint s, out Result result);
	}

	[CCode (lower_case_cprefix="gsl_sf_", cheader_filename="gsl/gsl_sf_clausen.h")]
	namespace Clausen
	{
		public static double clausen (double x);
		public static int clausen_e (double x, out Result result);
	}

	[CCode (lower_case_cprefix="gsl_sf_", cheader_filename="gsl/gsl_sf_coulomb.h")]
	namespace Hydrogenic
	{
		public static double hydrogenicR_1 (double z, double r);
		public static int hydrogenicR_1_e (double z, double r, out Result result);
		public static double hydrogenicR (int n, int l, double z, double r);
		public static int hydrogenicR_e (int n, int l, double z, double r, out Result result);
	}

	[CCode (lower_case_cprefix="gsl_sf_coulomb_wave_", cheader_filename="gsl/gsl_sf_coulomb.h")]
	namespace CoulombWave
	{
		public static int FG_e (double eta, double x, double l_f, int k, out Result f, out Result fp, out Result g, out Result gp, out double exp_f, out double exp_g);
		public static int F_array (double l_min, int kmax, double eta, double x, [CCode (array_length = false)] double[] fc_array, out double f_exponent);
		public static int FG_array (double l_min, int kmax, double eta, double x, [CCode (array_length = false)] double[] fc_array, [CCode (array_length = false)] double[] gc_array, out double f_exponent, out double g_exponent);
		public static int FGp_array (double l_min, int kmax, double eta, double x, [CCode (array_length = false)] double[] fc_array, [CCode (array_length = false)] double[] fcp_array, [CCode (array_length = false)] double[] gc_array, [CCode (array_length = false)] double[] gcp_array, out double f_exponent, out double g_exponent);
		public static int sphF_array (double l_min, int kmax, double eta, double x, [CCode (array_length = false)] double[] fc_array, [CCode (array_length = false)] double[] f_exponent);
	}

	[CCode (lower_case_cprefix="gsl_sf_coulomb_", cheader_filename="gsl/gsl_sf_coulomb.h")]
	namespace Coulomb
	{
		public static int CL_e (double l, double eta, out Result result);
		public static int CL_array (double lmin, int kmax, double eta, [CCode (array_length = false)] double[] cl);
	}

	[CCode (lower_case_cprefix="gsl_sf_coupling_", cheader_filename="gsl/gsl_coupling.h")]
	namespace Coupling
	{
		public static double 3j (int two_ja, int two_jb, int two_jc, int two_ma, int two_mb, int two_mc);
		public static int 3j_e (int two_ja, int two_jb, int two_jc, int two_ma, int two_mb, int two_mc, out Result result);

		public static double 6j (int two_ja, int two_jb, int two_jc, int two_jd, int two_je, int two_jf);
		public static int 6j_e (int two_ja, int two_jb, int two_jc, int two_jd, int two_je, int two_jf, out Result result);

		public static double 9j (int two_ja, int two_jb, int two_jc, int two_jd, int two_je, int two_jf, int two_jg, int two_jh, int two_ji);
		public static int 9j_e (int two_ja, int two_jb, int two_jc, int two_jd, int two_je, int two_jf, int two_jg, int two_jh, int two_ji, out Result result);
	}

	[CCode (lower_case_cprefix="gsl_sf_", cheader_filename="gsl/gsl_sf_dawson.h")]
	namespace Dawson
	{
		public static double dawson (double x);
		public static int dawson_e (double x, out Result result);
	}

	[CCode (cheader_filename="gsl/gsl_sf_debye.h")]
	namespace Debye
	{
		[CCode (cname="gsl_sf_debye_1")]
		public static double D1 (double x);
		[CCode (cname="gsl_sf_debye_1_e")]
		public static int D1_e (double x, out Result result);
		[CCode (cname="gsl_sf_debye_2")]
		public static double D2 (double x);
		[CCode (cname="gsl_sf_debye_2_e")]
		public static int D2_e (double x, out Result result);
		[CCode (cname="gsl_sf_debye_3")]
		public static double D3 (double x);
		[CCode (cname="gsl_sf_debye_3_e")]
		public static int D3_e (double x, out Result result);
		[CCode (cname="gsl_sf_debye_4")]
		public static double D4 (double x);
		[CCode (cname="gsl_sf_debye_4_e")]
		public static int D4_e (double x, out Result result);
		[CCode (cname="gsl_sf_debye_5")]
		public static double D5 (double x);
		[CCode (cname="gsl_sf_debye_5_e")]
		public static int D5_e (double x, out Result result);
		[CCode (cname="gsl_sf_debye_6")]
		public static double D6 (double x);
		[CCode (cname="gsl_sf_debye_6_e")]
		public static int D6_e (double x, out Result result);
	}

	[CCode (lower_case_cprefix="gsl_sf_", cheader_filename="gsl/gsl_sf_dilog.h")]
	namespace Dilog
	{
		public static double dilog (double x);
		public static int dilog_e (double x, out Result result);
		public static int complex_dilog_e (double r, double theta, out Result result_re, out Result result_im);
	}

	[CCode (lower_case_cprefix="gsl_sf_multiply_", cheader_filename="gsl/gsl_sf_elementary.h")]
	namespace Multiply
	{
		public static int e (double x, double y, out Result result);
		public static int err_e (double x, double dx, double y, double dy, out Result result);
	}

	[CCode (lower_case_cprefix="gsl_sf_ellint_", cheader_filename="gsl/gsl_sf_ellint.h")]
	namespace EllInt
	{
		public static double Kcomp (double k, Mode mode);
		public static int Kcomp_e (double k, Mode mode, out Result result);
		public static double Ecomp (double k, Mode mode);
		public static int Ecomp_e (double k, Mode mode, out Result result);
		public static double Pcomp (double k, double n, Mode mode);
		public static int Pcomp_e (double k, double n, Mode mode, out Result result);

		public static double F (double phi, double k, Mode mode);
		public static int F_e (double phi, double k, Mode mode, out Result result);
		public static double E (double phi, double k, Mode mode);
		public static int E_e (double phi, double k, Mode mode, out Result result);
		public static double P (double phi, double k, double n, Mode mode);
		public static int P_e (double phi, double k, double n, Mode mode, out Result result);
		public static double D (double phi, double k, double n, Mode mode);
		public static int D_e (double phi, double k, double n, Mode mode, out Result result);

		public static double RC (double x, double y, Mode mode);
		public static int RC_e (double x, double y, Mode mode, out Result result);
		public static double RD (double x, double y, double z, Mode mode);
		public static int RD_e (double x, double y, double z, Mode mode, out Result result);
		public static double RF (double x, double y, double z, Mode mode);
		public static int RF_e (double x, double y, double z, Mode mode, out Result result);
		public static double RJ (double x, double y, double z, double p, Mode mode);
		public static int RJ_e (double x, double y, double z, double p, Mode mode, out Result result);
	}

	[CCode (lower_case_cprefix="gsl_sf_elljac_", cheader_filename="gsl/gsl_elljac.h")]
	namespace EllJac
	{
		public static int e (double u, double m, out double sn, out double cn, out double dn);
	}

	[CCode (lower_case_cprefix="gsl_sf_", cheader_filename="gsl/gsl_sf_erf.h")]
	namespace Erf
	{
		public static double erf (double x);
		public static int erf_e (double x, out Result result);
		public static double erf_Z (double x);
		public static int erf_Z_e (double x, out Result result);
		public static double erf_Q (double x);
		public static int erf_Q_e (double x, out Result result);
		public static double erfc (double x);
		public static int erfc_e (double x, out Result result);
		public static double log_erfc (double x);
		public static int log_erfc_e (double x, out Result result);
		public static double hazard (double x);
		public static int hazard_e (double x, out Result result);
	}

	[CCode (lower_case_cprefix="gsl_sf_", cheader_filename="gsl/gsl_sf_exp.h")]
	namespace Exp
	{
		public static double exp (double x);
		public static int exp_e (double x, out Result result);
		public static int exp_e10_e (double x, out ResultE10 result);
		public static double exp_mult (double x, double y);
		public static int exp_mult_e (double x, double y, out Result result);
		public static int exp_mult_e10_e (double x, double y, out ResultE10 result);
		public static int exp_err_e (double x, double dx, out Result result);
		public static int exp_err_e10_e (double x, double dx, out ResultE10 result);
		public static int exp_mul_err_e (double x, double dx, double y, double dy, out Result result);
		public static int exp_mul_err_e10_e (double x, double dx, double y, double dy, out ResultE10 result);
		public static double expm1 (double x);
		public static int expm1_e (double x, out Result result);
		public static double exprel (double x);
		public static int exprel_e (double x, out Result result);
		public static double exprel_2 (double x);
		public static int exprel_2_e (double x, out Result result);
		public static double exprel_n (int n, double x);
		public static int exprel_n_e (int n, double x, out Result result);
	}

	[CCode (lower_case_cprefix="gsl_sf_", cheader_filename="gsl/gsl_sf_expint.h")]
	namespace Expint
	{
		public static double expint_E1 (double x);
		public static int expint_E1_e (double x, out Result result);
		public static double expint_E2 (double x);
		public static int expint_E2_e (double x, out Result result);
		public static double expint_En (int n, double x);
		public static int expint_En_e (int n, double x, out Result result);
		public static double expint_Ei (double x);
		public static int expint_Ei_e (double x, out Result result);
		public static double expint_Ei_3 (double x);
		public static int expint_Ei_3_e (double x, out Result result);
		public static double Shi (double x);
		public static int Shi_e (double x, out Result result);
		public static double Chi (double x);
		public static int Chi_e (double x, out Result result);
		public static double Si (double x);
		public static int Si_e (double x, out Result result);
		public static double Ci (double x);
		public static int Ci_e (double x, out Result result);
		public static double atanint (double x);
		public static double atanint_e (double x, out Result result);
	}

	[CCode (lower_case_cprefix="gsl_sf_fermi_dirac_", cheader_filename="gsl/gsl_sf_fermi_dirach.h")]
	namespace FermiDirac
	{
		public static double m1 (double x);
		public static int m1_e (double x, out Result result);
		[CCode (cname="gsl_sf_fermi_dirac_0")]
		public static double F0 (double x);
		[CCode (cname="gsl_sf_fermi_dirac_0_e")]
		public static int F0_e (double x, out Result result);
		[CCode (cname="gsl_sf_fermi_dirac_1")]
		public static double F1 (double x);
		[CCode (cname="gsl_sf_fermi_dirac_1_e")]
		public static int F1_e (double x, out Result result);
		[CCode (cname="gsl_sf_fermi_dirac_2")]
		public static double F2 (double x);
		[CCode (cname="gsl_sf_fermi_dirac_2_e")]
		public static int F2_e (double x, out Result result);
		[CCode (cname="gsl_sf_fermi_dirac_int")]
		public static double Fint (int j, double x);
		[CCode (cname="gsl_sf_fermi_dirac_int_e")]
		public static int Fint_e (int j, double x, out Result result);
		public static double mhalf (double x);
		public static int mhalf_e (double x, out Result result);
		public static double half (double x);
		public static int half_e (double x, out Result result);
		public static double 3half (double x);
		public static int 3half_e (double x, out Result result);
		public static double inc_0 (double x, double b);
		public static int inc_0_e (double x, double b, out Result result);
	}

	[CCode (lower_case_cprefix="gsl_sf_", cheader_filename="gsl/gsl_sf_gamma.h")]
	namespace GammaBeta
	{
		public static double gamma (double x);
		public static int gamma_e (double x, out Result result);
		public static double lngamma (double x);
		public static int lngamma_e (double x, out Result result);
		public static int lngamma_sgn_e (double x, out Result result, out double sgn);
		public static double gammastar (double x);
		public static int gammastar_e (double x, out Result result);
		public static double gammainv (double x);
		public static int gammainv_e (double x, out Result result);
		public static int lngamma_complex_e (double zr, double zi, out Result lnr, out Result arg);

		public static double fact (uint n);
		public static int fact_e (uint n, out Result result);
		public static double doublefact (uint n);
		public static int doublefact_e (uint n, out Result result);
		public static double lnfact (uint n);
		public static int lnfact_e (uint n, out Result result);
		public static double lndoublefact (uint n);
		public static int lndoublefact_e (uint n, out Result result);
		public static double choose (uint n, uint m);
		public static int choose_e (uint n, uint m, out Result result);
		public static double lnchoose (uint n, uint m);
		public static int lnchoose_e (uint n, uint m, out Result result);
		public static double taylorcoeff (int n, double x);
		public static int taylorcoeff_e (int n, double x, out Result result);

		public static double poch (double a, double x);
		public static int poch_e (double a, double x, out Result result);
		public static double lnpoch (double a, double x);
		public static int lnpoch_e (double a, double x, out Result result);
		public static int lnpoch_sgn_e (double a, double x, out Result result, out double sgn);
		public static double pochrel (double a, double x);
		public static int pochrel_e (double a, double x, out Result result);

		public static double gamma_inc (double a, double x);
		public static int gamma_inc_e (double a, double x, out Result result);
		public static double gamma_inc_Q (double a, double x);
		public static int gamma_inc_Q_e (double a, double x, out Result result);
		public static double gamma_inc_P (double a, double x);
		public static int gamma_inc_P_e (double a, double x, out Result result);

		public static double beta (double a, double b);
		public static int beta_e (double a, double b, out Result result);
		public static double lnbeta (double a, double b);
		public static int lnbeta_e (double a, double b, out Result result);

		public static double beta_inc (double a, double b, double x);
		public static int beta_inc_e (double a, double b, double x, out Result result);
	}

	[CCode (lower_case_cprefix="gsl_sf_gegenpoly_", cheader_filename="gsl/gsl_sf_gegenbauer.h")]
	namespace GegenPoly
	{
		[CCode (cname="gsl_sf_gegenpoly_1")]
		public static double C1 (double lambda, double x);
		[CCode (cname="gsl_sf_gegenpoly_1_e")]
		public static double C1_e (double lambda, double x, out Result result);
		[CCode (cname="gsl_sf_gegenpoly_2")]
		public static double C2 (double lambda, double x);
		[CCode (cname="gsl_sf_gegenpoly_2_e")]
		public static double C2_e (double lambda, double x, out Result result);
		[CCode (cname="gsl_sf_gegenpoly_3")]
		public static double C3 (double lambda, double x);
		[CCode (cname="gsl_sf_gegenpoly_3_e")]
		public static double C3_e (double lambda, double x, out Result result);
		[CCode (cname="gsl_sf_gegenpoly_n")]
		public static double Cn (double lambda, double x);
		[CCode (cname="gsl_sf_gegenpoly_n_e")]
		public static double Cn_e (double lambda, double x, out Result result);
		public static int array (int nmax, double lambda, double x, out Result result);
	}

	[CCode (lower_case_cprefix="gsl_sf_hyperg_", cheader_filename="gsl/gsl_sf_hyperg.h")]
	namespace Hyperg
	{
		public static double 0F1 (double c, double x);
		public static int 0F1_e (double c, double x, out Result result);
		public static double 1F1_int (int m, int n, double x);
		public static int 1F1_int_e (int m, int n, double x, out Result result);
		public static double 1F1 (double a, double b, double x);
		public static int 1F1_e (double a, double b, double x, out Result result);
		public static double U_int (int m, int n, double x);
		public static int U_int_e (int m, int n, double x, out Result result);
		public static int U_int_e10_e (int m, int n, double x, out ResultE10 result);
		public static double U (double a, double b, double x);
		public static int U_e (double a, double b, double x, out Result result);
		public static int U_e10_e (double a, double b, double x, out ResultE10 result);
		public static double 2F1 (double a, double b, double c, double x);
		public static int 2F1_e (double a, double b, double c, double x, out Result result);
		public static double 2F1_conj (double aR, double aI, double c, double x);
		public static int 2F1_conj_e (double aR, double aI, double c, double x, out Result result);
		public static double 2F1_renorm (double a, double b, double c, double x);
		public static int 2F1_renorm_e (double a, double b, double c, double x, out Result result);
		public static double 2F1_conj_renorm (double aR, double aI, double c, double x);
		public static int 2F1_conj_renorm_e (double aR, double aI, double c, double x, out Result result);
		public static double 2F0 (double a, double b, double x);
		public static int 2F0_e (double a, double b, double x, out Result result);
	}

	[CCode (cheader_filename="gsl/gsl_sf_laguerre.h")]
	namespace Laguerre
	{
		[CCode (cname="gsl_sf_laguerre_1")]
		public static double L1 (double a, double x);
		[CCode (cname="gsl_sf_laguerre_1_e")]
		public static double L1_e (double a, double x, out Result result);
		[CCode (cname="gsl_sf_laguerre_2")]
		public static double L2 (double a, double x);
		[CCode (cname="gsl_sf_laguerre_2_e")]
		public static double L2_e (double a, double x, out Result result);
		[CCode (cname="gsl_sf_laguerre_3")]
		public static double L3 (double a, double x);
		[CCode (cname="gsl_sf_laguerre_3_e")]
		public static double L3_e (double a, double x, out Result result);
		[CCode (cname="gsl_sf_laguerre_n")]
		public static double Ln (int n, double a, double x);
		[CCode (cname="gsl_sf_laguerre_n_e")]
		public static double Ln_e (int n, double a, double x, out Result result);
	}

	[CCode (lower_case_cprefix="gsl_sf_lambert_", cheader_filename="gsl/gsl_sf_lambert.h")]
	namespace Lambert
	{
		public static double W0 (double x);
		public static int W0_e (double x, out Result result);
		public static double Wm1 (double x);
		public static int Wm1_e (double x, out Result result);
	}

	[CCode (lower_case_cprefix="gsl_sf_legendre_", cheader_filename="gsl/gsl_sf_legendre.h")]
	namespace LegendrePoly
	{
		public static double P1 (double x);
		public static int P1_e (double x, out Result result);
		public static double P2 (double x);
		public static int P2_e (double x, out Result result);
		public static double P3 (double x);
		public static int P3_e (double x, out Result result);
		public static double Pl (int l, double x);
		public static int Pl_e (int l, double x, out Result result);
		public static int Pl_array (int lmax, double x, [CCode (array_length = false)] double[] result_array);
		public static int Pl_deriv_array (int lmax, double x, [CCode (array_length = false)] double[] result_array, [CCode (array_length = false)] double[] result_deriv_array);
		public static double Q0 (double x);
		public static int Q0_e (double x, out Result result);
		public static double Q1 (double x);
		public static int Q1_e (double x, out Result result);
		public static double Ql (int l, double x);
		public static int Ql_e (int l, double x, out Result result);

		public static double Plm (int l, int m, double x);
		public static int Plm_e (int l, int m, double x, out Result result);
		public static int Plm_array (int lmax, int m, double x, [CCode (array_length = false)] double[] result_array);
		public static int Plm_deriv_array (int lmax, int m, double x, double[] result_array, [CCode (array_length = false)] double[] result_deriv_array);
		public static double sphPlm (int l, int m, double x);
		public static int sphPlm_e (int l, int m, double x, out Result result);
		public static int sphPlm_array (int lmax, int m, double x, [CCode (array_length = false)] double[] result_array);
		public static int sphPlm_deriv_array (int lmax, int m, double x, double[] result_array, [CCode (array_length = false)] double[] result_deriv_array);
		public static int array_size (int lmax, int m);

		[CCode (cname="gsl_sf_conicalP_half")]
		public static double conicalP_half (double lambda, double x);
		[CCode (cname="gsl_sf_conicalP_half_e")]
		public static int conicalP_half_e (double lambda, double x, out Result result);
		[CCode (cname="gsl_sf_conicalP_mhalf")]
		public static double conicalP_mhalf (double lambda, double x);
		[CCode (cname="gsl_sf_conicalP_mhalf_e")]
		public static int conicalP_mhalf_e (double lambda, double x, out Result result);
		[CCode (cname="gsl_sf_conicalP_0")]
		public static double conicalP_0 (double lambda, double x);
		[CCode (cname="gsl_sf_conicalP_0_e")]
		public static int conicalP_0_e (double lambda, double x, out Result result);
		[CCode (cname="gsl_sf_conicalP_1")]
		public static double conicalP_1 (double lambda, double x);
		[CCode (cname="gsl_sf_conicalP_1_e")]
		public static int conicalP_1_e (double lambda, double x, out Result result);
		[CCode (cname="gsl_sf_conicalP_sph_reg")]
		public static double conicalP_sph_reg (int l, double lambda, double x);
		[CCode (cname="gsl_sf_conicalP_sph_reg_e")]
		public static int conicalP_sph_reg_e (int l, double lambda, double x, out Result result);
		[CCode (cname="gsl_sf_conicalP_cyl_reg")]
		public static double conicalP_cyl_reg (int m, double lambda, double x);
		[CCode (cname="gsl_sf_conicalP_cyl_reg_e")]
		public static int conicalP_cyl_reg_e (int m, double lambda, double x, out Result result);

		public static double H3d_0 (double lambda, double eta);
		public static int H3d_0_e (double lambda, double eta, out Result result);
		public static double H3d_1 (double lambda, double eta);
		public static int H3d_1_e (double lambda, double eta, out Result result);
		public static double H3d (int l, double lambda, double eta);
		public static int H3d_e (int l, double lambda, double eta, out Result result);
		public static int H3d_array (int lmax, double lambda, double eta, [CCode (array_length = false)] double[] result_array);
	}

	[CCode (lower_case_cprefix="gsl_sf_", cheader_filename="gsl/gsl_sf_log.h")]
	namespace Log
	{
		public static double log (double x);
		public static int log_e (double x, out Result result);
		public static double log_abs (double x);
		public static int log_abs_e (double x, out Result result);
		public static int complex_log_e (double zr, double zi, out Result result, out Result theta);
		public static double log_1plusx (double x);
		public static int log_1plusx_e (double x, out Result result);
		public static double log_1plusx_mx (double x);
		public static int log_1plusx_mx_e (double x, out Result result);
	}

	[Compact]
	[CCode (cname="gsl_sf_mathieu_workspace", cprefix="gsl_sf_mathieu_", cheader_filename="gsl/gsl_sf_mathieu.h")]
	public class MathieuWorkspace
	{
		public size_t size;
		public size_t even_order;
		public size_t odd_order;
		public int extra_values;
		public double qa;
		public double qb;
		public double* aa;
		public double* bb;
		public double* dd;
		public double* ee;
		public double* tt;
		public double* e2;
		public double* zz;
		public Vector eval;
		public Matrix evec;
		public EigenSymmvWorkspace wmat;

		public static int a_array (int order_min, int order_max, double qq, MathieuWorkspace work, [CCode (array_length = false)] double[] result_array);
		public static int b_array (int order_min, int order_max, double qq, MathieuWorkspace work, [CCode (array_length = false)] double[] result_array);
		public static int a (int order, double qq, out Result result);
		public static int b (int order, double qq, out Result result);
		public static int a_coeff (int order, double qq, double aa, [CCode (array_length = false)] double[] coeff);
		public static int b_coeff (int order, double qq, double aa, [CCode (array_length = false)] double[] coeff);

		[CCode (cname="gsl_sf_mathieu_alloc")]
		public MathieuWorkspace (size_t nn, double qq);

		public static int ce (int order, double qq, double zz, out Result result);
		public static int se (int order, double qq, double zz, out Result result);
		public static int ce_array (int nmin, int nmax, double qq, double zz, MathieuWorkspace work, [CCode (array_length = false)] double[] result_array);
		public static int se_array (int nmin, int nmax, double qq, double zz, MathieuWorkspace work, [CCode (array_length = false)] double[] result_array);

		public static int Mc (int kind, int order, double qq, double zz, out Result result);
		public static int Ms (int kind, int order, double qq, double zz, out Result result);
		public static int Mc_array (int kind, int nmin, int nmax, double qq, double zz, MathieuWorkspace work, [CCode (array_length = false)] double[] result_array);
		public static int Ms_array (int kind, int nmin, int nmax, double qq, double zz, MathieuWorkspace work, [CCode (array_length = false)] double[] result_array);
	}

	[CCode (lower_case_cprefix="gsl_sf_", cheader_filename="gsl/gsl_sf_pow_int.h")]
	namespace Pow
	{
		public static double pow_int (double x, int n);
		public static int pow_int_e (double x, int n, out Result result);
	}

	[CCode (lower_case_cprefix="gsl_sf_", cheader_filename="gsl/gsl_sf_psi.h")]
	namespace Psi
	{
		public static double psi_int (int n);
		public static int psi_int_e (int n, out Result result);
		public static double psi (double x);
		public static int psi_e (double x, out Result result);
		public static double psi_1piy (double y);
		public static int psi_1piy_e (double y, out Result result);

		public static double psi_1_int (int n);
		public static int psi_1_int_e (int n, out Result result);
		public static double psi_1 (double x);
		public static int psi_1_e (double x, out Result result);

		public static double psi_n (int n, double x);
		public static int psi_e_n (int n, double x, out Result result);
	}

	[CCode (lower_case_cprefix="gsl_sf_", cheader_filename="gsl/gsl_sf_synchrotron.h")]
	namespace Synchrotron
	{
		public static double synchrotron_1 (double x);
		public static int synchrotron_1_e (double x, out Result result);
		public static double synchrotron_2 (double x);
		public static double synchrotron_2_e (double x, out Result result);
	}

	[CCode (lower_case_cprefix="gsl_sf_", cheader_filename="gsl/gsl_sf_transport.h")]
	namespace Transport
	{
		public static double transport_2 (double x);
		public static int transport_2_e (double x, out Result result);
		public static double transport_3 (double x);
		public static int transport_3_e (double x, out Result result);
		public static double transport_4 (double x);
		public static int transport_4_e (double x, out Result result);
		public static double transport_5 (double x);
		public static int transport_5_e (double x, out Result result);
	}

	[CCode (lower_case_cprefix="gsl_sf_", cheader_filename="gsl/gsl_sf_trig.h")]
	namespace Trig
	{
		public static double sin (double x);
		public static int sin_e (double x, out Result result);
		public static double cos (double x);
		public static int cos_e (double x, out Result result);
		public static double hypot (double x, double y);
		public static int hypot_e (double x, double y, out Result result);
		public static double sinc (double x);
		public static int sinc_e (double x, out Result result);
		public static double complex_sin_e (double zr, double zi, out Result szr, out Result szi);
		public static double complex_cos_e (double zr, double zi, out Result czr, out Result czi);
		public static double complex_logsin_e (double zr, double zi, out Result lszr, out Result lszi);
		public static double lnsinh (double x);
		public static int lnsinh_e (double x, out Result result);
		public static double lncosh (double x);
		public static int lncosh_e (double x, out Result result);
		public static int polar_to_rect (double r, double theta, out Result x, out Result y);
		public static int rect_to_polar (double x, double y, out Result r, out Result theta);
		public static double angle_restrict_symm (double theta);
		public static int angle_restrict_symm_e (out double theta);
		public static double angle_restrict_pos (double theta);
		public static int angle_restrict_pos_e (out double theta);
		public static int sin_err_e (double x, double dx, out Result result);
		public static int cos_err_e (double x, double dx, out Result result);
	}

	[CCode (lower_case_cprefix="gsl_sf_", cheader_filename="gsl/gsl_sf_zeta.h")]
	namespace Zeta
	{
		public static double zeta_int (int n);
		public static int zeta_int_e (int n, out Result result);
		public static double zeta (double s);
		public static int zeta_e (double s, out Result result);
		public static double zetam1_int (int n);
		public static int zetam1_int_e (int n, out Result result);
		public static double zetam1 (double s);
		public static int zetam1_e (double s, out Result result);
		public static double hzeta (double s, double q);
		public static int hzeta_e (double s, double q, out Result result);
		public static double eta_int (int n);
		public static int eta_int_e (int n, out Result result);
		public static double eta (double s);
		public static int eta_e (double s, out Result result);
	}


	/*
	 * Blocks, Vectors and Matrices
	 */
	[Compact]
	[CCode (cname="gsl_block", cheader_filename="gsl/gsl_block_double.h")]
	public class Block
	{
		public size_t size;
		public double* data;

		[CCode (cname="gsl_block_alloc")]
		public Block (size_t n);
		[CCode (cname="gsl_block_calloc")]
		public Block.with_zeros (size_t n);

		[CCode (instance_pos=-1)]
		public int fwrite (GLib.FileStream stream);
		[CCode (instance_pos=-1)]
		public int fread (GLib.FileStream stream);
		public static int fprintf (GLib.FileStream stream, Block b, string format);
		[CCode (instance_pos=-1)]
		public int fscanf (GLib.FileStream stream);
	}

	[Compact]
	[CCode (cname="gsl_block_complex", cheader_filename="gsl/gsl_block_complex_double.h")]
	public class BlockComplex
	{
		public size_t size;
		public double* data;

		[CCode (cname="gsl_block_complex_alloc")]
		public BlockComplex (size_t n);
		[CCode (cname="gsl_block_complex_calloc")]
		public BlockComplex.with_zeros (size_t n);

		[CCode (instance_pos=-1)]
		public int fwrite (GLib.FileStream stream);
		[CCode (instance_pos=-1)]
		public int fread (GLib.FileStream stream);
		public static int fprintf (GLib.FileStream stream, BlockComplex b, string format);
		[CCode (instance_pos=-1)]
		public int fscanf (GLib.FileStream stream);
	}

	[SimpleType]
	[CCode (cname="gsl_vector_view", cheader_filename="gsl/gsl_vector_double.h", has_type_id = false)]
	public struct VectorView
	{
		public unowned Vector vector;

		public static VectorView array (double[] v);
		public static VectorView array_with_stride ([CCode (array_length = false)] double[] v, size_t stride, size_t n);
	}

	[Compact]
	[CCode (cname="gsl_vector", cheader_filename="gsl/gsl_vector_double.h")]
	public class Vector
	{
		public size_t size;
		public size_t stride;
		public double* data;
		public Block block;
		public int owner;

		[CCode (cname="gsl_vector_alloc")]
		public Vector (size_t n);
		[CCode (cname="gsl_vector_calloc")]
		public Vector.with_zeros (size_t n);
		[CCode (cname="gsl_vector_alloc_from_block")]
		public Vector.from_block (Block b, size_t offset, size_t n, size_t stride);
		[CCode (cname="gsl_vector_alloc_from_vector")]
		public Vector.from_vector (Vector v, size_t offset, size_t n, size_t stride);

		public double @get (size_t i);
		public void @set (size_t i, double x);
		public double* ptr (size_t i);

		public void set_all (double x);
		public void set_zero ();
		public void set_basis (size_t i);

		[CCode (instance_pos=-1)]
		public int fwrite (GLib.FileStream stream);
		[CCode (instance_pos=-1)]
		public int fread (GLib.FileStream stream);
		public static int fprintf (GLib.FileStream stream, Vector v, string format);
		[CCode (instance_pos=-1)]
		public int fscanf (GLib.FileStream stream);

		public VectorView subvector (size_t offset, size_t n);
		public VectorView subvector_with_stride (size_t offset, size_t stride, size_t n);

		public int memcpy (Vector src);
		public int swap (Vector w);

		public int swap_elements (size_t i, size_t j);
		public int reverse ();

		public int add (Vector b);
		public int sub (Vector b);
		public int mul (Vector b);
		public int div (Vector b);
		public int scale (double x);
		public int add_constant (double x);

		public double max ();
		public double min ();
		public void minmax (out double min_out, out double max_out);
		public size_t max_index ();
		public size_t min_index ();
		public void minmax_index (out size_t imin, out size_t imax);

		public bool isnull ();
		public bool ispos ();
		public bool isneg ();
		public bool isnonneg ();
	}

	[SimpleType]
	[CCode (cname="gsl_vector_complex_view", cheader_filename="gsl/gsl_vector_complex_double.h", has_type_id = false)]
	public struct VectorComplexView
	{
		public unowned VectorComplex vector;

		public static VectorComplexView array (double[] v);
		public static VectorComplexView array_with_stride ([CCode (array_length = false)] double[] v, size_t stride, size_t n);
	}

	[Compact]
	[CCode (cname="gsl_vector_complex", cheader_filename="gsl/gsl_vector_complex_double.h")]
	public class VectorComplex
	{
		public size_t size;
		public size_t stride;
		public double* data;
		public BlockComplex block;
		public int owner;

		[CCode (cname="gsl_vector_complex_alloc")]
		public VectorComplex (size_t n);
		[CCode (cname="gsl_vector_complex_calloc")]
		public VectorComplex.with_zeros (size_t n);
		[CCode (cname="gsl_vector_complex_alloc_from_block")]
		public VectorComplex.from_block (BlockComplex b, size_t offset, size_t n, size_t stride);
		[CCode (cname="gsl_vector_complex_alloc_from_vector")]
		public VectorComplex.from_vector (VectorComplex v, size_t offset, size_t n, size_t stride);

		public Complex @get (size_t i);
		public void @set (size_t i, Complex x);
		public Complex* ptr (size_t i);

		public void set_all (Complex x);
		public void set_zero ();
		public void set_basis (size_t i);

		[CCode (instance_pos=-1)]
		public int fwrite (GLib.FileStream stream);
		[CCode (instance_pos=-1)]
		public int fread (GLib.FileStream stream);
		public static int fprintf (GLib.FileStream stream, VectorComplex v, string format);
		[CCode (instance_pos=-1)]
		public int fscanf (GLib.FileStream stream);

		public VectorComplexView subvector (size_t i, size_t n);
		public VectorComplexView subvector_with_stride (size_t i, size_t stride, size_t n);
		public VectorView complex_real ();
		public VectorView complex_imag ();

		public int memcpy (VectorComplex src);
		public int swap (VectorComplex w);

		public int swap_elements (size_t i, size_t j);
		public int reverse ();

		public int add (VectorComplex b);
		public int sub (VectorComplex b);
		public int mul (VectorComplex b);
		public int div (VectorComplex b);
		public int scale (double x);
		public int add_constant (double x);

		public double max ();
		public double min ();
		public void minmax (out double min_out, out double max_out);
		public size_t max_index ();
		public size_t min_index ();
		public void minmax_index (out size_t imin, out size_t imax);

		public bool isnull ();
		public bool ispos ();
		public bool isneg ();
		public bool isnonneg ();
	}

	[SimpleType]
	[CCode (cname="gsl_matrix_view", cheader_filename="gsl/gsl_matrix_double.h", has_type_id = false)]
	public struct MatrixView
	{
		public unowned Matrix matrix;

		public static MatrixView array ([CCode (array_length = false)] double[] v, size_t n1, size_t n2);
		public static MatrixView array_with_tda ([CCode (array_length = false)] double[] v, size_t n1, size_t n2, size_t tda);
		public static MatrixView vector (Vector v, size_t n1, size_t n2);
		public static MatrixView vectr_with_tda (Vector v, size_t n1, size_t n2, size_t tda);
	}

	[Compact]
	[CCode (cname="gsl_matrix", cheader_filename="gsl/gsl_matrix_double.h")]
	public class Matrix
	{
		public size_t size1;
		public size_t size2;
		public size_t tda;
		public double* data;
		public Block block;
		public int owner;

		[CCode (cname="gsl_matrix_alloc")]
		public Matrix (size_t n1, size_t n2);
		[CCode (cname="gsl_matrix_calloc")]
		public Matrix.with_zeros (size_t n1, size_t n2);
		[CCode (cname="gsl_matrix_alloc_from_block")]
		public Matrix.from_block (Block b, size_t offset, size_t n1, size_t n2, size_t d2);
		[CCode (cname="gsl_matrix_alloc_from_matrix")]
		public Matrix.from_matrix (Matrix m, size_t k1, size_t k2, size_t n1, size_t n2);

		public Vector alloc_row_from_matrix (size_t i);
		public Vector alloc_col_from_matrix (size_t j);

		public double @get (size_t i, size_t j);
		public void @set (size_t i, size_t j, double x);
		public double* ptr (size_t i, size_t j);

		public void set_all (double x);
		public void set_zero ();
		public void set_identity ();

		[CCode (instance_pos=-1)]
		public int fwrite (GLib.FileStream stream);
		[CCode (instance_pos=-1)]
		public int fread (GLib.FileStream stream);
		public static int fprintf (GLib.FileStream stream, Matrix m, string format);
		[CCode (instance_pos=-1)]
		public int fscanf (GLib.FileStream stream);

		public MatrixView submatrix (size_t k, size_t k2, size_t n1, size_t n2);
		public VectorView row (size_t i);
		public VectorView column (size_t j);
		public VectorView subrow (size_t i, size_t offset, size_t n);
		public VectorView subcolumn (size_t i, size_t offset, size_t n);
		public VectorView diagonal ();
		public VectorView subdiagonal (size_t k);
		public VectorView superdiagonal (size_t k);

		public int memcpy (Matrix src);
		public int swap (Matrix m2);

		public static int get_row (Vector v, Matrix m, size_t i);
		public static int get_col (Vector v, Matrix m, size_t j);
		public int set_row (size_t i, Vector v);
		public int set_col (size_t j, Vector v);

		public int swap_rows (size_t i, size_t j);
		public int swap_columns (size_t i, size_t j);
		public int swap_rowcol (size_t i, size_t j);
		public int transpose_memcpy (Matrix src);
		public int transpose ();

		public int add (Matrix b);
		public int sub (Matrix b);
		public int mul_elements (Matrix b);
		public int div_elements (Matrix b);
		public int scale (double x);
		public int add_constant (double x);
		public int add_diagonal (double x);

		public double max ();
		public double min ();
		public void minmax (out double min_out, out double max_out);
		public void max_index (out size_t imax, out size_t jmax);
		public void min_index (out size_t imin, out size_t jmin);
		public void minmax_index (out size_t imin, out size_t jmin, out size_t imax, out size_t jmax);

		public bool isnull ();
		public bool ispos ();
		public bool isneg ();
		public bool isnonneg ();
	}

	[SimpleType]
	[CCode (cname="gsl_matrix_complex_view", cheader_filename="gsl/gsl_matrix_complex_double.h", has_type_id = false)]
	public struct MatrixComplexView
	{
		public unowned MatrixComplex matrix;

		public static MatrixComplexView array ([CCode (array_length = false)] double[] v, size_t n1, size_t n2);
		public static MatrixComplexView array_with_tda ([CCode (array_length = false)] double[] v, size_t n1, size_t n2, size_t tda);
		public static MatrixComplexView vector (VectorComplex v, size_t n1, size_t n2);
		public static MatrixComplexView vectr_with_tda (VectorComplex v, size_t n1, size_t n2, size_t tda);
	}

	[Compact]
	[CCode (cname="gsl_matrix_complex", cheader_filename="gsl/gsl_matrix_complex_double.h")]
	public class MatrixComplex
	{
		public size_t size1;
		public size_t size2;
		public size_t tda;
		public double* data;
		public BlockComplex block;
		public int owner;

		[CCode (cname="gsl_matrix_complex_alloc")]
		public MatrixComplex (size_t n1, size_t n2);
		[CCode (cname="gsl_matrix_complex_calloc")]
		public MatrixComplex.with_zeros (size_t n1, size_t n2);
		[CCode (cname="gsl_matrix_complex_alloc_from_block")]
		public MatrixComplex.from_block (BlockComplex b, size_t offset, size_t n1, size_t n2, size_t d2);
		[CCode (cname="gsl_matrix_complex_alloc_from_matrix")]
		public MatrixComplex.from_matrix (MatrixComplex m, size_t k1, size_t k2, size_t n1, size_t n2);

		public VectorComplex alloc_row_from_matrix (size_t i);
		public VectorComplex alloc_col_from_matrix (size_t j);

		public double @get (size_t i, size_t j);
		public void @set (size_t i, size_t j, double x);
		public double* ptr (size_t i, size_t j);

		public void set_all (double x);
		public void set_zero ();
		public void set_identity ();

		[CCode (instance_pos=-1)]
		public int fwrite (GLib.FileStream stream);
		[CCode (instance_pos=-1)]
		public int fread (GLib.FileStream stream);
		public static int fprintf (GLib.FileStream stream, MatrixComplex m, string format);
		[CCode (instance_pos=-1)]
		public int fscanf (GLib.FileStream stream);

		public MatrixComplexView submatrix (size_t k, size_t k2, size_t n1, size_t n2);
		public VectorComplexView row (size_t i);
		public VectorComplexView column (size_t j);
		public VectorComplexView subrow (size_t i, size_t offset, size_t n);
		public VectorComplexView subcolumn (size_t i, size_t offset, size_t n);
		public VectorComplexView diagonal ();
		public VectorComplexView subdiagonal (size_t k);
		public VectorComplexView superdiagonal (size_t k);

		public int memcpy (MatrixComplex src);
		public int swap (MatrixComplex m2);

		public static int get_row (VectorComplex v, MatrixComplex m, size_t i);
		public static int get_col (VectorComplex v, MatrixComplex m, size_t j);
		public int set_row (size_t i, VectorComplex v);
		public int set_col (size_t j, VectorComplex v);

		public int swap_rows (size_t i, size_t j);
		public int swap_columns (size_t i, size_t j);
		public int swap_rowcol (size_t i, size_t j);
		public int transpose_memcpy (MatrixComplex src);
		public int transpose ();

		public int add (MatrixComplex b);
		public int sub (MatrixComplex b);
		public int mul_elements (MatrixComplex b);
		public int div_elements (MatrixComplex b);
		public int scale (double x);
		public int add_constant (double x);
		public int add_diagonal (double x);

		public double max ();
		public double min ();
		public void minmax (out double min_out, out double max_out);
		public void max_index (out size_t imax, out size_t jmax);
		public void min_index (out size_t imin, out size_t jmin);
		public void minmax_index (out size_t imin, out size_t jmin, out size_t imax, out size_t jmax);

		public bool isnull ();
		public bool ispos ();
		public bool isneg ();
		public bool isnonneg ();
	}


	/*
	 * Permutations
	 */
	[Compact]
	[CCode (cname="gsl_permutation", cheader_filename="gsl/gsl_permutation.h")]
	public class Permutation
	{
		public size_t size;
		public size_t* data;

		[CCode (cname="gsl_permutation_alloc")]
		public Permutation (size_t n);
		[CCode (cname="gsl_permutation_calloc")]
		public Permutation.with_zeros (size_t n);

		public void init ();
		public int memcpy (Permutation src);

		public size_t @get (size_t i);
		public int swap (size_t i, size_t j);

		public int valid ();

		public void reverse ();
		public int inverse (Permutation p);
		public int next ();
		public int prev ();

		public int mul (Permutation pa, Permutation pb);

		[CCode (instance_pos=-1)]
		public int fwrite (GLib.FileStream stream);
		[CCode (instance_pos=-1)]
		public int fread (GLib.FileStream stream);
		public static int fprintf (GLib.FileStream stream, Permutation p, string format);
		[CCode (instance_pos=-1)]
		public int fscanf (GLib.FileStream stream);

		public int linear_to_canonical (Permutation p);
		public int canonical_to_linear (Permutation q);
		public size_t inversions ();
		public size_t linear_cycles ();
		public size_t canonical_cycles ();
	}

	[CCode (lower_case_cprefix="gsl_", cheader_filename="gsl/gsl_permute_double.h")]
	namespace Permute
	{
		public static int permute (size_t* p, [CCode (array_length = false)] double[] data, size_t stride, size_t n);
		public static int permute_inverse (size_t* p, [CCode (array_length = false)] double[] data, size_t stride, size_t n);
	}

	[CCode (cheader_filename="gsl/gsl_permute_complex_double.h")]
	namespace PermuteComplex
	{
		[CCode (cname="gsl_permute_complex")]
		public static int permute (size_t* p, [CCode (array_length = false)] double[] data, size_t stride, size_t n);
		[CCode (cname="gsl_permute_complex_inverse")]
		public static int permute_inverse (size_t* p, [CCode (array_length = false)] double[] data, size_t stride, size_t n);
	}

	[CCode (cheader_filename="gsl/gsl_permute_vector_double.h")]
	namespace PermuteVector
	{
		[CCode (cname="gsl_permute_vector")]
		public static int permute (Permutation p, Vector v);
		[CCode (cname="gsl_permute_vector_inverse")]
		public static int permute_inverse (Permutation p, Vector v);
	}

	[CCode (cheader_filename="gsl/gsl_permute_vector_complex_double.h")]
	namespace PermuteVectorComplex
	{
		[CCode (cname="gsl_permute_vector_complex")]
		public static int permute (Permutation p, Vector v);
		[CCode (cname="gsl_permute_vector_complex_inverse")]
		public static int permute_inverse (Permutation p, Vector v);
	}


	/*
	 * Combinations
	 */
	[Compact]
	[CCode (cname="gsl_combination", cheader_filename="gsl/gsl_combination.h")]
	public class Combination
	{
		public size_t n;
		public size_t k;
		public size_t* data;

		[CCode (cname="gsl_combination_alloc")]
		public Combination (size_t n, size_t k);
		[CCode (cname="gsl_combination_calloc")]
		public Combination.with_zeros (size_t n, size_t k);

		public void init_first ();
		public void init_last ();
		public int memcpy (Combination src);

		public size_t @get (size_t i);

		public int valid ();

		public int next ();
		public int prev ();

		[CCode (instance_pos=-1)]
		public int fwrite (GLib.FileStream stream);
		[CCode (instance_pos=-1)]
		public int fread (GLib.FileStream stream);
		public static int fprintf (GLib.FileStream stream, Combination c, string format);
		[CCode (instance_pos=-1)]
		public int fscanf (GLib.FileStream stream);
	}


	/*
	 * Sorting
	 */
	[CCode (lower_case_cprefix="gsl_sort_", cheader_filename="gsl/gsl_sort_double.h")]
	namespace Sort
	{
		[CCode (cname="gsl_sort")]
		public static void sort ([CCode (array_length = false)] double[] data, size_t stride, size_t n);
		[CCode (cname="gsl_sort_index")]
		public static void sort_index ([CCode (array_length = false)] size_t[] p, [CCode (array_length = false)] double[] data, size_t stride, size_t n);
		public static int smallest ([CCode (array_length = false)] double[] dest, size_t k, [CCode (array_length = false)] double[] src, size_t stride, size_t n);
		public static int smallest_index ([CCode (array_length = false)] size_t[] p, size_t k, [CCode (array_length = false)] double[] src, size_t stride, size_t n);
		public static int largest ([CCode (array_length = false)] double[] dest, size_t k, [CCode (array_length = false)] double[] src, size_t stride, size_t n);
		public static int largest_index ([CCode (array_length = false)] size_t[] p, size_t k, [CCode (array_length = false)] double[] src, size_t stride, size_t n);
	}

	[CCode (lower_case_cprefix="gsl_sort_vector_", cheader_filename="gsl/gsl_sort_vector_double.h")]
	namespace SortVector
	{
		[CCode (cname="gsl_sort_vector")]
		public static void sort (Vector v);
		[CCode (cname="gsl_sort_vector_index")]
		public static int sort_index (Permutation p, Vector v);
		public static int smallest ([CCode (array_length = false)] double[] dest, size_t k, Vector v);
		public static int smallest_index ([CCode (array_length = false)] size_t[] p, size_t k, Vector v);
		public static int largest ([CCode (array_length = false)] double[] dest, size_t k, Vector v);
		public static int largest_index ([CCode (array_length = false)] size_t[] p, size_t k, Vector v);
	}


	/*
	 * Linear Algebra
	 */
	[CCode (lower_case_cprefix="gsl_linalg_", cheader_filename="gsl/gsl_linalg.h")]
	namespace LinAlg
	{
		public static int LU_decomp (Matrix A, Permutation p, out int signum);
		public static int complex_LU_decomp (MatrixComplex A, Permutation p, out int signum);
		public static int LU_solve (Matrix LU, Permutation p, Vector b, Vector x);
		public static int complex_LU_solve (MatrixComplex LU, Permutation p, VectorComplex b, VectorComplex x);
		public static int LU_svx (Matrix LU, Permutation p, Vector x);
		public static int complex_LU_svx (MatrixComplex LU, Permutation p, VectorComplex x);
		public static int LU_refine (Matrix A, Matrix LU, Permutation p, Vector b, Vector x, Vector residual);
		public static int complex_LU_refine (MatrixComplex A, MatrixComplex LU, Permutation p, VectorComplex b, VectorComplex x, VectorComplex residual);
		public static int LU_invert (Matrix LU, Permutation p, Matrix inverse);
		public static int complex_LU_invert (MatrixComplex LU, Permutation p, Matrix inverse);
		public static double LU_det (Matrix LU, int signum);
		public static Complex complex_LU_det (MatrixComplex LU, int signum);
		public static double LU_lndet (Matrix LU);
		public static double complex_LU_lndet (MatrixComplex LU);
		public static int LU_sgndet (Matrix LU, int signum);
		public static Complex complex_LU_sgndet (MatrixComplex LU, int signum);

		public static int QR_decomp (Matrix A, Vector tau);
		public static int QR_solve (Matrix QR, Vector tau, Vector b, Vector x);
		public static int QR_svx (Matrix QR, Vector tau, Vector x);
		public static int QR_lssolve (Matrix QR, Vector tau, Vector b, Vector x, Vector residual);
		public static int QR_QTvec (Matrix QR, Vector tau, Vector v);
		public static int QR_Qvec (Matrix QR, Vector tau, Vector v);
		public static int QR_QTmat (Matrix QR, Vector tau, Matrix A);
		public static int QR_Rsolve (Matrix QR, Vector b, Vector x);
		public static int QR_Rsvx (Matrix QR, Vector x);
		public static int QR_unpack (Matrix QR, Vector tau, Matrix Q, Matrix R);
		public static int QR_QRsolve (Matrix Q, Matrix R, Vector b, Vector x);
		public static int QR_update (Matrix Q, Matrix R, Vector w, Vector v);
		public static int R_solve (Matrix R, Vector b, Vector x);
		public static int R_svx (Matrix R, Vector x);

		public static int QRPT_decomp (Matrix A, Vector tau, Permutation p, out int signum, Vector norm);
		public static int QRPT_decomp2 (Matrix A, Matrix q, Matrix r, Vector tau, Permutation p, out int signum, Vector norm);
		public static int QRPT_solve (Matrix QR, Vector tau, Permutation p, Vector b, Vector x);
		public static int QRPT_svx (Matrix QR, Vector tau, Permutation p, Vector x);
		public static int QRPT_QRsolve (Matrix Q, Matrix R, Permutation p, Vector b, Vector x);
		public static int QRPT_update (Matrix Q, Matrix R, Permutation p, Vector u, Vector v);
		public static int QRPT_Rsolve (Matrix QR, Permutation p, Vector b, Vector x);
		public static int QRPT_Rsvx (Matrix QR, Permutation p, Vector x);

		public static int SV_decomp (Matrix A, Matrix V, Vector S, Vector work);
		public static int SV_decomp_mod (Matrix A, Matrix X, Matrix V, Vector S, Vector work);
		public static int SV_decomp_jacobi (Matrix A, Matrix V, Vector S);
		public static int SV_solve (Matrix U, Matrix V, Vector S, Vector b, Vector x);

		public static int cholesky_decomp (Matrix A);
		public static int complex_cholesky_decomp (MatrixComplex A);
		public static int cholesky_solve (Matrix cholesky, Vector b, Vector x);
		public static int complex_cholesky_solve (MatrixComplex cholesky, VectorComplex b, VectorComplex x);
		public static int cholesky_svx (Matrix cholesky, Vector x);
		public static int complex_cholesky_svx (MatrixComplex cholesky, VectorComplex x);

		public static int symmtd_decomp (Matrix A, Vector tau);
		public static int symmtd_unpack (Matrix A, Vector tau, Matrix Q, Vector diag, Vector subdiag);
		public static int symmtd_unpack_T (Matrix A, Vector diag, Vector subdiag);

		public static int hermtd_decomp (MatrixComplex A, VectorComplex tau);
		public static int hermtd_unpack (MatrixComplex A, VectorComplex tau, MatrixComplex Q, Vector diag, Vector subdiag);
		public static int hermtd_unpack_T (MatrixComplex A, Vector diag, Vector subdiag);

		public static int hessenberg_decomp (Matrix A, Vector tau);
		public static int hessenberg_unpack (Matrix H, Vector tau, Matrix U);
		public static int hessenberg_unpack_accum (Matrix H, Vector tau, Matrix V);
		public static int hessenberg_set_zero (Matrix H);

		public static int hesstri_decomp (Matrix A, Matrix B, Matrix U, Matrix V, Vector work);

		public static int bidiag_decomp (Matrix A, Vector tau_U, Vector tau_V);
		public static int bidiag_unpack (Matrix A, Vector tau_U, Matrix U, Vector tau_V, Matrix V, Vector diag, Vector superdiag);
		public static int bidiag_unpack2 (Matrix A, Vector tau_U, Vector tau_V, Matrix V);
		public static int bidiag_unpack_B (Matrix A, Vector diag, Vector superdiag);

		public static int householder_tansform (Vector v);
		public static Complex complex_householder_transform (VectorComplex V);
		public static int householder_hm (double tau, Vector v, Matrix A);
		public static int complex_householder_hm (Complex tau, VectorComplex V, MatrixComplex A);
		public static int householder_mh (double tau, Vector v, Matrix A);
		public static int complex_householder_mh (Complex tau, VectorComplex V, MatrixComplex A);
		public static int householder_hv (double tau, Vector v, Vector w);
		public static int complex_householder_hv (Complex tau, VectorComplex V, VectorComplex w);

		public static int HH_solve (Matrix A, Vector b, Vector x);
		public static int HH_svx (Matrix A, Vector x);

		public static int solve_tridiag (Vector diag, Vector e, Vector f, Vector b, Vector x);
		public static int solve_symm_tridiag (Vector diag, Vector e, Vector b, Vector x);
		public static int solve_cyc_tridiag (Vector diag, Vector e, Vector f, Vector b, Vector x);
		public static int solve_symm_cyc_tridiag (Vector diag, Vector e, Vector b, Vector x);

		public static int balance_matrix (Matrix A, Vector D);
	}


	/*
	 * Eigensystems
	 */
	[CCode (cname="gsl_eigen_sort_t", cprefix="GSL_EIGEN_SORT_", cheader_filename="gsl/gsl_eigen.h", has_type_id = false)]
	public enum EigenSortType
	{
		VAL_ASC,
		VAL_DESC,
		ABS_ASC,
		ABS_DESC
	}

	[Compact]
	[CCode (cname="gsl_eigen_symm_workspace", free_function="gsl_eigen_symm_free", cheader_filename="gsl/gsl_eigen.h")]
	public class EigenSymmWorkspace
	{
		public size_t size;
		public double* d;
		public double* sd;

		[CCode (cname="gsl_eigen_symm_alloc")]
		public EigenSymmWorkspace (size_t n);
		[CCode (cname="gsl_eigen_symm", instance_pos=-1)]
		public int init (Matrix A, Vector eval);
	}

	[Compact]
	[CCode (cname="gsl_eigen_symmv_workspace", free_function="gsl_eigen_symmv_free", cheader_filename="gsl/gsl_eigen.h")]
	public class EigenSymmvWorkspace
	{
		public size_t size;
		public double* d;
		public double* sd;
		public double* gc;
		public double* gs;

		[CCode (cname="gsl_eigen_symmv_alloc")]
		public EigenSymmvWorkspace (size_t n);
		[CCode (cname="gsl_eigen_symmv", instance_pos=-1)]
		public int init (Matrix A, Vector eval, Matrix evec);
	}

	[Compact]
	[CCode (cname="gsl_eigen_herm_workspace", free_function="gsl_eigen_herm_free", cheader_filename="gsl/gsl_eigen.h")]
	public class EigenHermWorkspace
	{
		public size_t size;
		public double* d;
		public double* sd;
		public double* tau;

		[CCode (cname="gsl_eigen_herm_alloc")]
		public EigenHermWorkspace (size_t n);
		[CCode (cname="gsl_eigen_herm", instance_pos=-1)]
		public int init (MatrixComplex A, VectorComplex eval);
	}

	[Compact]
	[CCode (cname="gsl_eigen_hermv_workspace", free_function="gsl_eigen_hermv_free", cheader_filename="gsl/gsl_eigen.h")]
	public class EigenHermvWorkspace
	{
		public size_t size;
		public double* d;
		public double* sd;
		public double* tau;
		public double* gc;
		public double* gs;

		[CCode (cname="gsl_eigen_hermv_alloc")]
		public EigenHermvWorkspace (size_t n);
		[CCode (cname="gsl_eigen_hermv", instance_pos=-1)]
		public int init (MatrixComplex A, VectorComplex eval, MatrixComplex evec);
	}

	[Compact]
	[CCode (cname="gsl_eigen_nonsymm_workspace", free_function="gsl_eigen_nonsymm_free", cheader_filename="gsl/gsl_eigen.h")]
	public class EigenNonsymmWorkspace
	{
		public size_t size;
		public Vector diag;
		public Vector tau;
		public Matrix Z;
		public int do_balance;
		size_t n_evals;

		[CCode (cname="gsl_eigen_nonsymm_alloc")]
		public EigenNonsymmWorkspace (size_t n);
		[CCode (cname="gsl_eigen_nonsymm_params", instance_pos=-1)]
		public void params (int compute_t, int balance);
		[CCode (cname="gsl_eigen_nonsymm", instance_pos=-1)]
		public int init (Matrix A, VectorComplex eval);
		[CCode (cname="gsl_eigen_nonsymm_Z", instance_pos=-1)]
		public int init_Z (Matrix A, VectorComplex eval, Matrix Z);
	}

	[Compact]
	[CCode (cname="gsl_eigen_nonsymmv_workspace", free_function="gsl_eigen_nonsymmv_free", cheader_filename="gsl/gsl_eigen.h")]
	public class EigenNonsymmvWorkspace
	{
		public size_t size;
		public Vector work;
		public Vector work2;
		public Vector work3;
		public Matrix Z;
		public EigenNonsymmWorkspace nonsymm_workspace_p;

		[CCode (cname="gsl_eigen_nonsymmv_alloc")]
		public EigenNonsymmvWorkspace (size_t n);
		[CCode (cname="gsl_eigen_nonsymmv", instance_pos=-1)]
		public int init (Matrix A, VectorComplex eval, MatrixComplex evec);
		[CCode (cname="gsl_eigen_nonsymmv_Z", instance_pos=-1)]
		public int init_Z (Matrix A, VectorComplex eval, MatrixComplex evec, Matrix Z);
	}

	[Compact]
	[CCode (cname="gsl_eigen_gensymm_workspace", free_function="gsl_eigen_gensymm_free", cheader_filename="gsl/gsl_eigen.h")]
	public class EigenGensymmWorkspace
	{
		public size_t size;
		public EigenSymmWorkspace symm_workspace_p;

		[CCode (cname="gsl_eigen_gensymm_alloc")]
		public EigenGensymmWorkspace (size_t n);
		[CCode (cname="gsl_eigen_gensymm", instance_pos=-1)]
		public int init (Matrix A, Matrix B, Vector eval);
	}

	[Compact]
	[CCode (cname="gsl_eigen_gensymmv_workspace", free_function="gsl_eigen_gensymmv_free", cheader_filename="gsl/gsl_eigen.h")]
	public class EigenGensymmvWorkspace
	{
		public size_t size;
		public EigenSymmvWorkspace symmv_workspace_p;

		[CCode (cname="gsl_eigen_gensymmv_alloc")]
		public EigenGensymmvWorkspace (size_t n);
		[CCode (cname="gsl_eigen_gensymmv", instance_pos=-1)]
		public int init (Matrix A, Matrix B, Vector eval, Matrix evec);
	}

	[Compact]
	[CCode (cname="gsl_eigen_genherm_workspace", free_function="gsl_eigen_genherm_free", cheader_filename="gsl/gsl_eigen.h")]
	public class EigenGenhermWorkspace
	{
		public size_t size;
		public EigenHermWorkspace herm_workspace_p;

		[CCode (cname="gsl_eigen_genherm_alloc")]
		public EigenGenhermWorkspace (size_t n);
		[CCode (cname="gsl_eigen_genherm", instance_pos=-1)]
		public int init (MatrixComplex A, MatrixComplex B, Vector eval);
	}

	[Compact]
	[CCode (cname="gsl_eigen_genhermv_workspace", free_function="gsl_eigen_genhermv_free", cheader_filename="gsl/gsl_eigen.h")]
	public class EigenGenhermvWorkspace
	{
		public size_t size;
		public EigenHermvWorkspace hermv_workspace_p;

		[CCode (cname="gsl_eigen_genhermv_alloc")]
		public EigenGenhermvWorkspace (size_t n);
		[CCode (cname="gsl_eigen_genhermv", instance_pos=-1)]
		public int init (MatrixComplex A, MatrixComplex B, Vector eval, MatrixComplex evec);
	}

	[Compact]
	[CCode (cname="gsl_eigen_gen_workspace", free_function="gsl_eigen_gen_free", cheader_filename="gsl/gsl_eigen.h")]
	public class EigenGenWorkspace
	{
		public size_t size;
		public Vector work;
		public size_t n_evals;
		public size_t max_iterations;
		public size_t n_iter;
		public double eshift;
		public int needtop;
		public double atol;
		public double btol;
		public double ascale;
		public double bscale;
		public Matrix H;
		public Matrix R;
		public int compute_s;
		public int compute_t;
		public Matrix Q;
		public Matrix Z;

		[CCode (cname="gsl_eigen_gen_alloc")]
		public EigenGenWorkspace (size_t n);
		[CCode (cname="gsl_eigen_gen_params", instance_pos=-1)]
		public void params (int compute_s, int compute_t, int balance);
		[CCode (cname="gsl_eigen_gen", instance_pos=-1)]
		public int init (Matrix A, Matrix B, VectorComplex alpha, Vector beta);
		[CCode (cname="gsl_eigen_gen_QZ", instance_pos=-1)]
		public int init_QZ (Matrix A, Matrix B, VectorComplex alpha, Vector beta, Matrix Q, Matrix Z);
	}

	[Compact]
	[CCode (cname="gsl_eigen_genv_workspace", free_function="gsl_eigen_genv_free", cheader_filename="gsl/gsl_eigen.h")]
	public class EigenGenvWorkspace
	{
		public size_t size;
		public Vector work1;
		public Vector work2;
		public Vector work3;
		public Vector work4;
		public Vector work5;
		public Vector work6;
		public Matrix Q;
		public Matrix Z;
		public EigenGenWorkspace gen_workspace_p;

		[CCode (cname="gsl_eigen_genv_alloc")]
		public EigenGenvWorkspace (size_t n);
		[CCode (cname="gsl_eigen_genv", instance_pos=-1)]
		public int init (Matrix A, Matrix B, VectorComplex alpha, Vector beta, MatrixComplex evec);
		[CCode (cname="gsl_eigen_genv_QZ", instance_pos=-1)]
		public int init_QZ (Matrix A, Matrix B, VectorComplex alpha, Vector beta, MatrixComplex evec, Matrix Q, Matrix Z);
	}

	[CCode (lower_case_cprefix="gsl_eigen_", cheader_filename="gsl/gsl_eigen.h")]
	namespace EigenSort
	{
		public static int symmv_sort (Vector eval, Matrix evec, EigenSortType sort_type);
		public static int hermv_sort (Vector eval, MatrixComplex evec, EigenSortType sort_type);
		public static int nonsymmv_sort (VectorComplex eval, MatrixComplex evec, EigenSortType sort_type);
		public static int gensymmv_sort (Vector eval, Matrix evec, EigenSortType sort_type);
		public static int genhermv_sort (Vector eval, MatrixComplex evec, EigenSortType sort_type);
		public static int genv_sort (VectorComplex alpha, Vector beta, MatrixComplex evec, EigenSortType sort_type);
	}


	/*
	 * Fast Fourier Transforms (FFTs)
	 */
	[CCode (cname="gsl_fft_direction", cheader_filename="gsl/gsl_fft.h", has_type_id = false)]
	public enum FFTDirection
	{
		forward = -1,
		backward = 1
	}

	[Compact]
	[CCode (cname="gsl_fft_complex_wavetable", cheader_filename="gsl/gsl_fft_complex.h")]
	public class FFTComplexWavetable
	{
		public size_t n;
		public size_t nf;
		public size_t factor[64];
		public Complex twiddle[64];
		public Complex trig;

		[CCode (cname="gsl_fft_complex_wavetable_alloc")]
		public FFTComplexWavetable (size_t n);
		public int memcpy (FFTComplexWavetable src);
	}

	[Compact]
	[CCode (cname="gsl_fft_complex_workspace", cheader_filename="gsl/gsl_fft_complex.h")]
	public class FFTComplexWorkspace
	{
		size_t n;
		double *scratch;

		[CCode (cname="gsl_fft_complex_workspace_alloc")]
		public FFTComplexWorkspace (size_t n);
	}

	[Compact]
	[CCode (lower_case_cprefix="gsl_fft_complex_", cheader_filename="gsl/gsl_fft_complex.h")]
	namespace FFTComplex
	{
		public static int radix2_forward ([CCode (array_length = false)] double[] data, size_t stride, size_t n);
		public static int radix2_transform ([CCode (array_length = false)] double[] data, size_t stride, size_t n, FFTDirection sign);
		public static int radix2_backward ([CCode (array_length = false)] double[] data, size_t stride, size_t n);
		public static int radix2_inverse ([CCode (array_length = false)] double[] data, size_t stride, size_t n);
		public static int radix2_dif_forward ([CCode (array_length = false)] double[] data, size_t stride, size_t n);
		public static int radix2_dif_transform ([CCode (array_length = false)] double[] data, size_t stride, size_t n, FFTDirection sign);
		public static int radix2_dif_backward ([CCode (array_length = false)] double[] data, size_t stride, size_t n);
		public static int radix2_dif_inverse ([CCode (array_length = false)] double[] data, size_t stride, size_t n);

		public static int forward ([CCode (array_length = false)] double[] data, size_t stride, size_t n, FFTComplexWavetable wavetable, FFTComplexWorkspace work);
		public static int transform ([CCode (array_length = false)] double[] data, size_t stride, size_t n, FFTComplexWavetable wavetable, FFTComplexWorkspace work, FFTDirection sign);
		public static int backward ([CCode (array_length = false)] double[] data, size_t stride, size_t n, FFTComplexWavetable wavetable, FFTComplexWorkspace work);
		public static int inverse ([CCode (array_length = false)] double[] data, size_t stride, size_t n, FFTComplexWavetable wavetable, FFTComplexWorkspace work);
	}

	[Compact]
	[CCode (cname="gsl_fft_real_wavetable", cheader_filename="gsl/gsl_fft_real.h")]
	public class FFTRealWavetable
	{
		public size_t n;
		public size_t nf;
		public size_t factor[64];
		public Complex twiddle[64];
		public Complex trig;

		[CCode (cname="gsl_fft_real_wavetable_alloc")]
		public FFTRealWavetable (size_t n);
	}

	[Compact]
	[CCode (cname="gsl_fft_real_workspace", cheader_filename="gsl/gsl_fft_real.h")]
	public class FFTRealWorkspace
	{
		size_t n;
		double *scratch;

		[CCode (cname="gsl_fft_real_workspace_alloc")]
		public FFTRealWorkspace (size_t n);
	}

	[Compact]
	[CCode (lower_case_cprefix="gsl_fft_real_", cheader_filename="gsl/gsl_fft_real.h")]
	namespace FFTReal
	{
		public static int radix2_forward ([CCode (array_length = false)] double[] data, size_t stride, size_t n);
		public static int transform ([CCode (array_length = false)] double[] data, size_t stride, size_t n, FFTRealWavetable wavetable, FFTRealWorkspace work);
		public static int unpack ([CCode (array_length = false)] double[] real_coefficient, [CCode (array_length = false)] double[] complex_coeficient, size_t stride, size_t n);
	}

	[Compact]
	[CCode (cname="gsl_fft_halfcomplex_wavetable", cheader_filename="gsl/gsl_fft_halfcomplex.h")]
	public class FFTHalfcomplexWavetable
	{
		public size_t n;
		public size_t nf;
		public size_t factor[64];
		public Complex twiddle[64];
		public Complex trig;

		[CCode (cname="gsl_fft_halfcomplex_wavetable_alloc")]
		public FFTHalfcomplexWavetable (size_t n);
	}

	[CCode (lower_case_cprefix="gsl_fft_halfcomplex_", cheader_filename="gsl/gsl_fft_halfcomplex.h")]
	namespace FFTHalfcomplex
	{
		public static int radix2_inverse ([CCode (array_length = false)] double[] data, size_t stride, size_t n);
		public static int radix2_backward ([CCode (array_length = false)] double[] data, size_t stride, size_t n);
		public static int radix2_transform ([CCode (array_length = false)] double[] data, size_t stride, size_t n);
		public static int backward ([CCode (array_length = false)] double[] data, size_t stride, size_t n, FFTHalfcomplexWavetable wavetable, FFTRealWorkspace work);
		public static int inverse ([CCode (array_length = false)] double[] data, size_t stride, size_t n, FFTHalfcomplexWavetable wavetable, FFTRealWorkspace work);
		public static int transform ([CCode (array_length = false)] double[] data, size_t stride, size_t n, FFTHalfcomplexWavetable wavetable, FFTRealWorkspace work);
		public static int unpack ([CCode (array_length = false)] double[] halfcomplex_coefficient, [CCode (array_length = false)] double[] complex_coefficient, size_t stride, size_t n);
		public static int radix2_unpack ([CCode (array_length = false)] double[] halfcomplex_coefficient, [CCode (array_length = false)] double[] complex_coefficient, size_t stride, size_t n);
	}


	/*
	 * Numerical Integration
	 */
	[CCode (cprefix="GSL_INTEG_", cheader_filename="gsl/gsl_integration.h", has_type_id = false)]
	public enum QAWO
	{
		COSINE,
		SINE
	}

	[CCode (cprefix="GSL_INTEG_", cheader_filename="gsl/gsl_integration.h", has_type_id = false)]
	public enum GaussRules
	{
		GAUSS15,
		GAUSS21,
		GAUSS31,
		GAUSS41,
		GAUSS51,
		GAUSS61
	}

	[Compact]
	[CCode (cname="gsl_integration_workspace", cheader_filename="gsl/gsl_integration.h")]
	public class IntegrationWorkspace
	{
		public size_t limit;
		public size_t size;
		public size_t nrmax;
		public size_t i;
		public size_t maximum_level;
		public double* alist;
		public double* blist;
		public double* rlist;
		public double* elist;
		public size_t* order;
		public size_t* level;

		[CCode (cname="gsl_integration_workspace_alloc")]
		public IntegrationWorkspace (size_t n);
	}

	[Compact]
	[CCode (cname="gsl_integration_qaws_table", cheader_filename="gsl/gsl_integration.h")]
	public class IntegrationQAWSTable
	{
		public double alpha;
		public double beta;
		public int mu;
		public int nu;
		public double ri[25];
		public double rj[25];
		public double rg[25];
		public double rh[25];

		[CCode (cname="gsl_integration_qaws_table_alloc")]
		public IntegrationQAWSTable (double alpha, double beta, int mu, int nu);
		public int @set (double alpha, double beta, int mu, int nu);
	}

	[Compact]
	[CCode (cname="gsl_integration_qawo_table", free_function="gsl_integration_qawo_table_free", cheader_filename="gsl/gsl_integration.h")]
	public class IntegrationQAWOTable
	{
		public size_t n;
		public double omega;
		public double L;
		public double par;
		public QAWO sine;
		public double* chebmo;

		[CCode (cname="gsl_integration_qawo_table_alloc")]
		public IntegrationQAWOTable (double omega, double L, QAWO sine, size_t n);
		public int @set (double omega, double L, QAWO sine);
		public int set_length (double L);
	}

	[CCode (cname="gsl_integration", cheader_filename="gsl/gsl_integration.h")]
	namespace Integration
	{
		public static void qk15 (Function* f, double a, double b, out double result, out double abserr, out double resabs, out double resasc);
		public static void qk21 (Function* f, double a, double b, out double result, out double abserr, out double resabs, out double resasc);
		public static void qk31 (Function* f, double a, double b, out double result, out double abserr, out double resabs, out double resasc);
		public static void qk41 (Function* f, double a, double b, out double result, out double abserr, out double resabs, out double resasc);
		public static void qk51 (Function* f, double a, double b, out double result, out double abserr, out double resabs, out double resasc);
		public static void qk61 (Function* f, double a, double b, out double result, out double abserr, out double resabs, out double resasc);
		public static void qcheb (Function* f, double a, double b, out double cheb12, out double cheb24);

		public static void qk (int n, [CCode (array_length = false)] double[] xgk, [CCode (array_length = false)] double[] wg, [CCode (array_length = false)] double[] wgk, [CCode (array_length = false)] double[] fv1, [CCode (array_length = false)] double[] fv2, Function* f, double a, double b, out double result, out double abserr, out double resabs, double resasc);
		public static int qng (Function* f, double a, double b, double epsabs, double epsrel, out double result, out double abserr, out size_t neval);
		public static int qag (Function* f, double a, double b, double epsabs, double epsrel, size_t limit, int key, IntegrationWorkspace workspace, out double result, out double abserr);
		public static int qagi (Function* f, double epsabs, double epsrel, size_t limit, IntegrationWorkspace workspace, out double result, out double abserr);
		public static int qagiu (Function* f, double a, double epsabs, double epsrel, size_t limit, IntegrationWorkspace workspace, out double result, out double abserr);
		public static int qagil (Function* f, double b, double epsabs, double epsrel, size_t limit, IntegrationWorkspace workspace, out double result, out double abserr);
		public static int qags (Function* f, double a, double b, double epsabs, double epsrel, size_t limit, IntegrationWorkspace workspace, out double result, out double abserr);
		public static int qagp (Function* f, [CCode (array_length = false)] double[] pts, size_t npts, double epsabs, double epsrel, size_t limit, IntegrationWorkspace workspace, out double result, out double abserr);
		public static int qawc (Function* f, double a, double b, double c, double epsabs, double epsrel, size_t limit, IntegrationWorkspace workspace, out double result, out double abserr);
		public static int qaws (Function* f, double a, double b, IntegrationQAWSTable t, double epsabs, double epsrel, size_t limit, IntegrationWorkspace workspace, out double result, out double abserr);
		public static int qawo (Function* f, double a, double epsabs, double epsrel, size_t limit, IntegrationWorkspace workspace, IntegrationQAWOTable wf, out double result, out double abserr);
		public static int qawf (Function* f, double a, double epsabs, size_t limit, IntegrationWorkspace workspace, IntegrationWorkspace cycle_workspace, IntegrationQAWOTable wf, out double result, out double abserr);
	}


	/*
	 * Random Number Generation
	 */
	[CCode (has_target = false)]
	public delegate void RNGSetState (void *state, ulong seed);
	[CCode (has_target = false)]
	public delegate ulong RNGGetState (void* state);
	[CCode (has_target = false)]
	public delegate double RNGGetDouble (void* state);

	[SimpleType]
	[CCode (cname="gsl_rng_type", cheader_filename="gsl/gsl_rng.h", has_type_id = false)]
	public struct RNGType
	{
		public string name;
		public ulong max;
		public ulong min;
		public size_t size;
		public RNGSetState @set;
		public RNGGetState @get;
		public RNGGetDouble get_double;
	}

	[CCode (lower_case_cprefix="gsl_rng_", cheader_filename="gsl/gsl_rng.h")]
	namespace RNGTypes
	{
		public static RNGType* borosh13;
		public static RNGType* coveyou;
		public static RNGType* cmrg;
		public static RNGType* fishman18;
		public static RNGType* fishman20;
		public static RNGType* fishman2x;
		public static RNGType* gfsr4;
		public static RNGType* knuthran;
		public static RNGType* knuthran2;
		public static RNGType* knuthran2002;
		public static RNGType* lecuyer21;
		public static RNGType* minstd;
		public static RNGType* mrg;
		public static RNGType* mt19937;
		public static RNGType* mt19937_1999;
		public static RNGType* mt19937_1998;
		public static RNGType* r250;
		public static RNGType* ran0;
		public static RNGType* ran1;
		public static RNGType* ran2;
		public static RNGType* ran3;
		public static RNGType* rand;
		public static RNGType* rand48;
		public static RNGType* random128_bsd;
		public static RNGType* random128_glibc2;
		public static RNGType* random128_libc5;
		public static RNGType* random256_bsd;
		public static RNGType* random256_glibc2;
		public static RNGType* random256_libc5;
		public static RNGType* random32_bsd;
		public static RNGType* random32_glibc2;
		public static RNGType* random32_libc5;
		public static RNGType* random64_bsd;
		public static RNGType* random64_glibc2;
		public static RNGType* random64_libc5;
		public static RNGType* random8_bsd;
		public static RNGType* random8_glibc2;
		public static RNGType* random8_libc5;
		public static RNGType* random_bsd;
		public static RNGType* random_glibc2;
		public static RNGType* random_libc5;
		public static RNGType* randu;
		public static RNGType* ranf;
		public static RNGType* ranlux;
		public static RNGType* ranlux389;
		public static RNGType* ranlxd1;
		public static RNGType* ranlxd2;
		public static RNGType* ranlxs0;
		public static RNGType* ranlxs1;
		public static RNGType* ranlxs2;
		public static RNGType* ranmar;
		public static RNGType* slatec;
		public static RNGType* taus;
		public static RNGType* taus2;
		public static RNGType* taus113;
		public static RNGType* transputer;
		public static RNGType* tt800;
		public static RNGType* uni;
		public static RNGType* uni32;
		public static RNGType* vax;
		public static RNGType* waterman14;
		public static RNGType* zuf;
		public static RNGType* @default;
		public static ulong default_seed;
	}

	[Compact]
	[CCode (cname="gsl_rng", cheader_filename="gsl/gsl_rng.h")]
	public class RNG
	{
		public RNGType* type;
		public void* state;

		[CCode (cname="gsl_rng_alloc")]
		public RNG (RNGType* T);
		public void @set (ulong s);
		public ulong @get ();
		public double uniform ();
		public double uniform_pos ();
		public ulong uniform_int (ulong n);
		public string name ();
		public ulong max ();
		public ulong min ();
		public size_t size ();
		public static RNGType* env_setup ();
		public int memcpy (RNG src);
		public RNG clone ();

		[CCode (instance_pos=-1)]
		public int fwrite (GLib.FileStream stream);
		[CCode (instance_pos=-1)]
		public int fread (GLib.FileStream stream);

		public void print_state ();
	}

	[CCode (lower_case_cprefix="gsl_cdf_", cheader_filename="gsl/gsl_cdf.h")]
	namespace CDF
	{
		public static double ugaussian_P (double x);
		public static double ugaussian_Q (double x);

		public static double ugaussian_Pinv (double P);
		public static double ugaussian_Qinv (double Q);

		public static double gaussian_P (double x, double sigma);
		public static double gaussian_Q (double x, double sigma);

		public static double gaussian_Pinv (double P, double sigma);
		public static double gaussian_Qinv (double Q, double sigma);

		public static double gamma_P (double x, double a, double b);
		public static double gamma_Q (double x, double a, double b);

		public static double gamma_Pinv (double P, double a, double b);
		public static double gamma_Qinv (double Q, double a, double b);

		public static double cauchy_P (double x, double a);
		public static double cauchy_Q (double x, double a);

		public static double cauchy_Pinv (double P, double a);
		public static double cauchy_Qinv (double Q, double a);

		public static double laplace_P (double x, double a);
		public static double laplace_Q (double x, double a);

		public static double laplace_Pinv (double P, double a);
		public static double laplace_Qinv (double Q, double a);

		public static double rayleigh_P (double x, double sigma);
		public static double rayleigh_Q (double x, double sigma);

		public static double rayleigh_Pinv (double P, double sigma);
		public static double rayleigh_Qinv (double Q, double sigma);

		public static double chisq_P (double x, double nu);
		public static double chisq_Q (double x, double nu);

		public static double chisq_Pinv (double P, double nu);
		public static double chisq_Qinv (double Q, double nu);

		public static double exponential_P (double x, double mu);
		public static double exponential_Q (double x, double mu);

		public static double exponential_Pinv (double P, double mu);
		public static double exponential_Qinv (double Q, double mu);

		public static double exppow_P (double x, double a, double b);
		public static double exppow_Q (double x, double a, double b);

		public static double tdist_P (double x, double nu);
		public static double tdist_Q (double x, double nu);

		public static double tdist_Pinv (double P, double nu);
		public static double tdist_Qinv (double Q, double nu);

		public static double fdist_P (double x, double nu1, double nu2);
		public static double fdist_Q (double x, double nu1, double nu2);

		public static double fdist_Pinv (double P, double nu1, double nu2);
		public static double fdist_Qinv (double Q, double nu1, double nu2);

		public static double beta_P (double x, double a, double b);
		public static double beta_Q (double x, double a, double b);

		public static double beta_Pinv (double P, double a, double b);
		public static double beta_Qinv (double Q, double a, double b);

		public static double flat_P (double x, double a, double b);
		public static double flat_Q (double x, double a, double b);

		public static double flat_Pinv (double P, double a, double b);
		public static double flat_Qinv (double Q, double a, double b);

		public static double lognormal_P (double x, double zeta, double sigma);
		public static double lognormal_Q (double x, double zeta, double sigma);

		public static double lognormal_Pinv (double P, double zeta, double sigma);
		public static double lognormal_Qinv (double Q, double zeta, double sigma);

		public static double gumbel1_P (double x, double a, double b);
		public static double gumbel1_Q (double x, double a, double b);

		public static double gumbel1_Pinv (double P, double a, double b);
		public static double gumbel1_Qinv (double Q, double a, double b);

		public static double gumbel2_P (double x, double a, double b);
		public static double gumbel2_Q (double x, double a, double b);

		public static double gumbel2_Pinv (double P, double a, double b);
		public static double gumbel2_Qinv (double Q, double a, double b);

		public static double weibull_P (double x, double a, double b);
		public static double weibull_Q (double x, double a, double b);

		public static double weibull_Pinv (double P, double a, double b);
		public static double weibull_Qinv (double Q, double a, double b);

		public static double pareto_P (double x, double a, double b);
		public static double pareto_Q (double x, double a, double b);

		public static double pareto_Pinv (double P, double a, double b);
		public static double pareto_Qinv (double Q, double a, double b);

		public static double logistic_P (double x, double a);
		public static double logistic_Q (double x, double a);

		public static double logistic_Pinv (double P, double a);
		public static double logistic_Qinv (double Q, double a);

		public static double binomial_P (uint k, double p, uint n);
		public static double binomial_Q (uint k, double p, uint n);

		public static double poisson_P (uint k, double mu);
		public static double poisson_Q (uint k, double mu);

		public static double geometric_P (uint k, double p);
		public static double geometric_Q (uint k, double p);

		public static double negative_binomial_P (uint k, double p, double n);
		public static double negative_binomial_Q (uint k, double p, double n);

		public static double pascal_P (uint k, double p, uint n);
		public static double pascal_Q (uint k, double p, uint n);

		public static double hypergeometric_P (uint k, uint n1, uint n2, uint t);
		public static double hypergeometric_Q (uint k, uint n1, uint n2, uint t);
	}


	/*
	 * Quasi-Random Sequences
	 */
	[CCode (has_target = false)]
	public delegate size_t QRNGStateSize (uint dimension);
	[CCode (has_target = false)]
	public delegate int QRNGInitState (void* state, uint dimension);
	[CCode (has_target = false)]
	public delegate int QRNGGetState2 (void* state, uint dimension, out double x);

	[SimpleType]
	[CCode (cname="gsl_qrng_type", cheader_filename="gsl/gsl_qrng.h", has_type_id = false)]
	public struct QRNGType
	{
  		public string name;
  		public uint max_dimension;
  		public QRNGStateSize state_size;
  		public QRNGInitState init_state;
  		public QRNGGetState2 @get;
  	}

	[CCode (lower_case_cprefix="gsl_qrng_", cheader_filename="gsl/gsl_qrng.h")]
	namespace QRNGAlgorithms
	{
		public static QRNGType* niederreiter_2;
		public static QRNGType* sobol;
		public static QRNGType* halton;
		public static QRNGType* reversehalton;
	}

  	[Compact]
	[CCode (cname="gsl_qrng", cheader_filename="gsl/gsl_qrng.h")]
  	public class QRNG
  	{
  		public QRNGType* type;
  		public uint dimension;
  		size_t state_size;
  		void* state;

  		[CCode (cname="gsl_qrng_alloc")]
		public QRNG (QRNGType* T, uint d);
  		public void init ();
  		public int memcpy (QRNG src);
  		public QRNG clone ();
  		public string name ();
  		public size_t size ();
  		public int @get ([CCode (array_length = false)] double[] x);
  	}


  	/*
  	 * Random Number Distributions
  	 */
  	[CCode (lower_case_cprefix="gsl_ran_", cheader_filename="gsl/gsl_randist.h")]
	namespace Randist
	{
		public static uint bernoulli (RNG r, double p);
		public static double bernoulli_pdf (uint k, double p);

		public static double beta (RNG r, double a, double b);
		public static double beta_pdf (double x, double a, double b);

		public static uint binomial (RNG r, double p, uint n);
		public static uint binomial_knuth (RNG r, double p, uint n);
		public static uint binomial_tpe (RNG r, double p, uint n);
		public static double binomial_pdf (uint k, double p, uint n);

		public static double exponential (RNG r, double mu);
		public static double exponential_pdf (double x, double mu);

		public static double exppow (RNG r, double a, double b);
		public static double exppow_pdf (double x, double a, double b);

		public static double cauchy (RNG r, double a);
		public static double cauchy_pdf (double x, double a);

		public static double chisq (RNG r, double nu);
		public static double chisq_pdf (double x, double nu);

		public static void dirichlet (RNG r, size_t K, out double alpha, out double theta);
		public static double dirichlet_pdf (size_t K, out double alpha, out double theta);
		public static double dirichlet_lnpdf (size_t K, out double alpha, out double theta);

		public static double erlang (RNG r, double a, double n);
		public static double erlang_pdf (double x, double a, double n);

		public static double fdist (RNG r, double nu1, double nu2);
		public static double fdist_pdf (double x, double nu1, double nu2);

		public static double flat (RNG r, double a, double b);
		public static double flat_pdf (double x, double a, double b);

		public static double gamma (RNG r, double a, double b);
		public static double gamma_int (RNG r, uint a);
		public static double gamma_pdf (double x, double a, double b);
		public static double gamma_mt (RNG r, double a, double b);
		public static double gamma_knuth (RNG r, double a, double b);

		public static double gaussian (RNG r, double sigma);
		public static double gaussian_ratio_method (RNG r, double sigma);
		public static double gaussian_ziggurat (RNG r, double sigma);
		public static double gaussian_pdf (double x, double sigma);

		public static double ugaussian (RNG r);
		public static double ugaussian_ratio_method (RNG r);
		public static double ugaussian_pdf (double x);

		public static double gaussian_tail (RNG r, double a, double sigma);
		public static double gaussian_tail_pdf (double x, double a, double sigma);

		public static double ugaussian_tail (RNG r, double a);
		public static double ugaussian_tail_pdf (double x, double a);

		public static void bivariate_gaussian (RNG r, double sigma_x, double sigma_y, double rho, out double x, out double y);
		public static double bivariate_gaussian_pdf (double x, double y, double sigma_x, double sigma_y, double rho);

		public static double landau (RNG r);
		public static double landau_pdf (double x);

		public static uint geometric (RNG r, double p);
		public static double geometric_pdf (uint k, double p);

		public static uint hypergeometric (RNG r, uint n1, uint n2, uint t);
		public static double hypergeometric_pdf (uint k, uint n1, uint n2, uint t);

		public static double gumbel1 (RNG r, double a, double b);
		public static double gumbel1_pdf (double x, double a, double b);

		public static double gumbel2 (RNG r, double a, double b);
		public static double gumbel2_pdf (double x, double a, double b);

		public static double logistic (RNG r, double a);
		public static double logistic_pdf (double x, double a);

		public static double lognormal (RNG r, double zeta, double sigma);
		public static double lognormal_pdf (double x, double zeta, double sigma);

		public static uint logarithmic (RNG r, double p);
		public static double logarithmic_pdf (uint k, double p);

		public static void multinomial (RNG r, size_t K, uint N, [CCode (array_length = false)] double[] p, [CCode (array_length = false)] uint[] n);
		public static double multinomial_pdf (size_t K, [CCode (array_length = false)] double[] p, [CCode (array_length = false)] uint[] n);
		public static double multinomial_lnpdf (size_t K, [CCode (array_length = false)] double[] p, [CCode (array_length = false)] uint[] n);

		public static uint negative_binomial (RNG r, double p, double n);
		public static double negative_binomial_pdf (uint k, double p, double n);

		public static uint pascal (RNG r, double p, uint n);
		public static double pascal_pdf (uint k, double p, uint n);

		public static double pareto (RNG r, double a, double b);
		public static double pareto_pdf (double x, double a, double b);

		public static uint poisson (RNG r, double mu);
		public static void poisson_array (RNG r, size_t n, [CCode (array_length = false)] uint[] array, double mu);
		public static double poisson_pdf (uint k, double mu);

		public static double rayleigh (RNG r, double sigma);
		public static double rayleigh_pdf (double x, double sigma);

		public static double rayleigh_tail (RNG r, double a, double sigma);
		public static double rayleigh_tail_pdf (double x, double a, double sigma);

		public static double tdist (RNG r, double nu);
		public static double tdist_pdf (double x, double nu);

		public static double laplace (RNG r, double a);
		public static double laplace_pdf (double x, double a);

		public static double levy (RNG r, double c, double alpha);
		public static double levy_skew (RNG r, double c, double alpha, double beta);

		public static double weibull (RNG r, double a, double b);
		public static double weibull_pdf (double x, double a, double b);

		public static void dir_2d (RNG r, out double x, out double y);
		public static void dir_2d_trig_method (RNG r, out double x, out double y);
		public static void dir_3d (RNG r, out double x, out double y, out double z);
		public static void dir_nd (RNG r, size_t n, out double x);

		public static void shuffle (RNG r, void* b, size_t nmembm, size_t size);
		public static int choose (RNG r, void* dest, size_t k, void* src, size_t n, size_t size);
		public static void sample (RNG r, void* dest, size_t k, void* src, size_t n, size_t size);
	}

	[Compact]
	[CCode (cname="gsl_ran_discrete_t", cprefix="gsl_ran_discrete_", cheader_filename="gsl/gsl_randist.h")]
	public class RanDiscrete
	{
		public size_t K;
		public size_t* A;
		public double* F;

		[CCode (cname="gsl_ran_discrete_preproc")]
		public RanDiscrete (size_t K, double* P);
		[CCode (cname="gsl_ran_discrete")]
		public size_t discrete (RNG g);
		[CCode (instance_pos=-1)]
		public double pdf (size_t k);
	}


	/*
	 * Statistics
	 */
	[CCode (lower_case_cprefix="gsl_stats_", cheader_filename="gsl/gsl_statistics.h")]
	namespace Stats
	{
		public static double mean ([CCode (array_length = false)] double[] data, size_t stride, size_t n);
		public static double variance ([CCode (array_length = false)] double[] data, size_t stride, size_t n);
		public static double variance_m ([CCode (array_length = false)] double[] data, size_t stride, size_t n, double mean);
		public static double sd ([CCode (array_length = false)] double[] data, size_t stride, size_t n);
		public static double sd_m ([CCode (array_length = false)] double[] data, size_t stride, size_t n, double mean);
		public static double tss ([CCode (array_length = false)] double[] data, size_t stride, size_t n);
		public static double tss_m ([CCode (array_length = false)] double[] data, size_t stride, size_t n, double mean);
		public static double variance_with_fixed_mean ([CCode (array_length = false)] double[] data, size_t stride, size_t n, double mean);
		public static double sd_with_fixed_mean ([CCode (array_length = false)] double[] data, size_t stride, size_t n, double mean);
		public static double absdev ([CCode (array_length = false)] double[] data, size_t stride, size_t n);
		public static double absdev_m ([CCode (array_length = false)] double[] data, size_t stride, size_t n, double mean);
		public static double skew ([CCode (array_length = false)] double[] data, size_t stride, size_t n);
		public static double skew_m_sd ([CCode (array_length = false)] double[] data, size_t stride, size_t n, double mean, double sd);
		public static double kurtosis ([CCode (array_length = false)] double[] data, size_t stride, size_t n);
		public static double kurtosis_m_sd ([CCode (array_length = false)] double[] data, size_t stride, size_t n, double mean, double sd);
		public static double lag1_autocorrelation ([CCode (array_length = false)] double[] data, size_t stride, size_t n);
		public static double lag1_autocorrelation_m ([CCode (array_length = false)] double[] data, size_t stride, size_t n, double mean);
		public static double covariance ([CCode (array_length = false)] double[] data1, size_t stride1, [CCode (array_length = false)] double[] data2, size_t stride2, size_t n);
		public static double covariance_m ([CCode (array_length = false)] double[] data1, size_t stride1, [CCode (array_length = false)] double[] data2, size_t stride2, size_t n, double mean1, double mean2);
		public static double correlation ([CCode (array_length = false)] double[] data1, size_t stride1, [CCode (array_length = false)] double[] data2, size_t stride2, size_t n);

		public static double wmean ([CCode (array_length = false)] double[] w, size_t wstride, [CCode (array_length = false)] double[] data, size_t stride, size_t n);
		public static double wvariance ([CCode (array_length = false)] double[] w, size_t wstride, [CCode (array_length = false)] double[] data, size_t stride, size_t n);
		public static double wvariance_m ([CCode (array_length = false)] double[] w, size_t wstride, [CCode (array_length = false)] double[] data, size_t stride, size_t n, double wmean);
		public static double wsd ([CCode (array_length = false)] double[] w, size_t wstride, [CCode (array_length = false)] double[] data, size_t stride, size_t n);
		public static double wsd_m ([CCode (array_length = false)] double[] w, size_t wstride, [CCode (array_length = false)] double[] data, size_t stride, size_t n, double wmean);
		public static double wtss ([CCode (array_length = false)] double[] w, size_t wstride, [CCode (array_length = false)] double[] data, size_t stride, size_t n);
		public static double wtss_m ([CCode (array_length = false)] double[] w, size_t wstride, [CCode (array_length = false)] double[] data, size_t stride, size_t n, double mean);
		public static double wvariance_with_fixed_mean ([CCode (array_length = false)] double[] w, size_t wstride, [CCode (array_length = false)] double[] data, size_t stride, size_t n, double wmean);
		public static double wsd_with_fixed_mean ([CCode (array_length = false)] double[] w, size_t wstride, [CCode (array_length = false)] double[] data, size_t stride, size_t n, double wmean);
		public static double wabsdev ([CCode (array_length = false)] double[] w, size_t wstride, [CCode (array_length = false)] double[] data, size_t stride, size_t n);
		public static double wabsdev_m ([CCode (array_length = false)] double[] w, size_t wstride, [CCode (array_length = false)] double[] data, size_t stride, size_t n, double wmean);
		public static double wskew ([CCode (array_length = false)] double[] w, size_t wstride, [CCode (array_length = false)] double[] data, size_t stride, size_t n);
		public static double wskew_m_sd ([CCode (array_length = false)] double[] w, size_t wstride, [CCode (array_length = false)] double[] data, size_t stride, size_t n, double wmean, double wsd);
		public static double wkurtosis ([CCode (array_length = false)] double[] w, size_t wstride, [CCode (array_length = false)] double[] data, size_t stride, size_t n);
		public static double wkurtosis_m_sd ([CCode (array_length = false)] double[] w, size_t wstride, [CCode (array_length = false)] double[] data, size_t stride, size_t n, double wmean, double wsd);

		public static double max ([CCode (array_length = false)] double[] data, size_t stride, size_t n);
		public static double min ([CCode (array_length = false)] double[] data, size_t stride, size_t n);
		public static void minmax (out double min, out double max, [CCode (array_length = false)] double[] data, size_t stride, size_t n);
		public static size_t max_index ([CCode (array_length = false)] double[] data, size_t stride, size_t n);
		public static size_t min_index ([CCode (array_length = false)] double[] data, size_t stride, size_t n);
		public static void minmax_index (out size_t min, out size_t max, [CCode (array_length = false)] double[] data, size_t stride, size_t n);

		public static double median_from_sorted_data ([CCode (array_length = false)] double[] sorted_data, size_t stride, size_t n);
		public static double quantile_from_sorted_data ([CCode (array_length = false)] double[] sorted_data, size_t stride, size_t n, double f);
	}


	/*
	 * Histograms
	 */
	[Compact]
	[CCode (cname="gsl_histogram", cheader_filename="gsl/gsl_histogram.h")]
	public class Histogram
	{
		public size_t n;
		public double* range;
		public double* bin;

		[CCode (cname="gsl_histogram_alloc")]
		public Histogram (size_t n);
		[CCode (cname="gsl_histogram_calloc")]
		public Histogram.with_zeros (size_t n);
		[CCode (cname="gsl_histogram_calloc_uniform")]
		public Histogram.uniform (size_t n, double xmin, double xmax);
		[CCode (cname="gsl_histogram_calloc_range")]
		public Histogram.with_range (size_t n, [CCode (array_length = false)] double[] range);

		public int increment (double x);
		public int accumulate (double x, double weight);
		public int find (double x, out size_t i);
		public double @get (size_t i);
		public int get_range (size_t i, out double lower, out double upper);
		public double max ();
		public double min ();
		public size_t bins ();

		public void reset ();

		public int set_ranges (double[] range);
		public int set_ranges_uniform (double xmin, double xmax);

		public int memcpy (Histogram source);
		public Histogram clone();

		public double max_val ();
		public size_t max_bin ();
		public double min_val ();
		public size_t min_bin ();

		public int equal_bins_p (Histogram h2);
		public int add (Histogram h2);
		public int sub (Histogram h2);
		public int mul (Histogram h2);
		public int div (Histogram h2);
		public int scale (double scale);
		public int shift (double shift);

		public double sigma ();
		public double mean ();
		public double sum ();

		[CCode (instance_pos=-1)]
		public int fwrite (GLib.FileStream stream);
		[CCode (instance_pos=-1)]
		public int fread (GLib.FileStream stream);
		public static int fprintf (GLib.FileStream stream, Histogram h, string range_format, string bin_format);
		[CCode (instance_pos=-1)]
		public int fscanf (GLib.FileStream stream);
	}

	[Compact]
	[CCode (cname="gsl_histogram_pdf", cheader_filename="gsl/gsl_histogram.h")]
	public class HistogramPDF
	{
		public size_t n;
		public double* range;
		public double* sum ;

		[CCode (cname="gsl_histogram_pdf_alloc")]
		public HistogramPDF (size_t n);
		public int init (Histogram h);
		public double sample (double r);
	}

	[Compact]
	[CCode (cname="gsl_histogram2d", cheader_filename="gsl/gsl_histogram2d.h")]
	public class Histogram2d
	{
		public size_t nx;
		public size_t ny;
		public double* xrange;
		public double* yrange;
		public double* bin;

		[CCode (cname="gsl_histogram2d_alloc")]
		public Histogram2d (size_t nx, size_t ny);
		[CCode (cname="gsl_histogram2d_calloc")]
		public Histogram2d.with_zeros (size_t nx, size_t ny);
		[CCode (cname="gsl_histogram2d_calloc_uniform")]
		public Histogram2d.uniform (size_t nx, size_t ny, double xmin, double xmax, double ymin, double ymax);
		[CCode (cname="gsl_histogram2d_calloc_range")]
		public Histogram2d.range (size_t nx, size_t ny, out double xrange, out double yrange);

		public int increment (double x, double y);
		public int accumulate (double x, double y, double weight);
		public int find (double x, double y, out size_t i, out size_t j);
		public double @get (size_t i, size_t j);
		public int get_xrange (size_t i, out double xlower, out double xupper);
		public int get_yrange (size_t j, out double ylower, out double yupper);

		public double xmax ();
		public double xmin ();
		public double ymax ();
		public double ymin ();

		public void reset ();

		public int set_ranges_uniform (double xmin, double xmax, double ymin, double ymax);
		public int set_ranges (double[] xrange, double[] yrange);

		public int memcpy (Histogram2d source);
		public Histogram2d clone ();

		public double max_val();
		public void max_bin (out size_t i, out size_t j);
		public double min_val();
		public void min_bin (out size_t i, out size_t j);

		public double xmean ();
		public double ymean ();
		public double xsigma ();
		public double ysigma ();
		public double cov ();

		public double sum ();
		public int equal_bins_p (Histogram h2) ;
		public int add (Histogram h2);
		public int sub (Histogram h2);
		public int mul (Histogram2d h2);
		public int div (Histogram2d h2);
		public int scale (double scale);
		public int shift (double shift);

		[CCode (instance_pos=-1)]
		public int fwrite (GLib.FileStream stream);
		[CCode (instance_pos=-1)]
		public int fread (GLib.FileStream stream);
		public static int fprintf (GLib.FileStream stream, Histogram h, string range_format, string bin_format);
		[CCode (instance_pos=-1)]
		public int fscanf (GLib.FileStream stream);
	}

	[Compact]
	[CCode (cname="gsl_histogram2d_pdf", cheader_filename="gsl/gsl_histogram2d.h")]
	public class Histogram2dPDF
	{
		public size_t nx;
		public size_t ny;
		public double* xrange;
		public double* yrange;
		public double* sum;

		[CCode (cname="gsl_histogram2d_pdf_alloc")]
		public Histogram2dPDF (size_t nx, size_t ny);
		public int init (Histogram2d h);
		public int sample (double r1, double r2, out double x, out double y);
	}


	/*
	 * N-Tuples
	 */
	[CCode (has_target = false)]
	public delegate int NTupleFunc (void* ntuple_data, void* params);

	[SimpleType]
	[CCode (cname="gsl_ntuple_select_fn", cheader_filename="gsl/gsl_ntuple.h", has_type_id = false)]
	public struct NTupleSelectFn
	{
		public NTupleFunc function;
		public void* params;
	}

	[SimpleType]
	[CCode (cname="gsl_ntuple_value_fn", cheader_filename="gsl/gsl_ntuple.h", has_type_id = false)]
	public struct NTupleValueFn
	{
		public NTupleFunc function;
		public void* params;
	}

	[Compact]
	[CCode (cname="gsl_ntuple", free_function="gsl_ntuple_close", cheader_filename="gsl/gsl_ntuple.h")]
	public class NTuple
	{
		public GLib.FileStream file;
		public void* ntrupel_data;
		public size_t size;

		public static NTuple open (string filename, void* ntuple_data, size_t size);
		public static NTuple create (string filename, void* ntuple_data, size_t size);
		public int write ();
		public int read ();
		public int bookdata ();

		public static int project (Histogram h, NTuple ntuple, NTupleValueFn* value_func, NTupleSelectFn* select_func);
	}


	/*
	 * Monte Carlo Integration
	 */
	[CCode (cprefix="GSL_VEGAS_MODE_", cheader_filename="gsl/gsl_monte_vegas.h", has_type_id = false)]
	public enum MonteVegasMode
	{
		IMPORTANCE,
		IMPORTANCE_ONLY,
		STRATIFIED
	}

	[CCode (has_target = false)]
	public delegate double MonteFunc ([CCode (array_length = false)] double[] x_array, size_t dim, void* params);

	[SimpleType]
	[CCode (cname="gsl_monte_function", cheader_filename="gsl/gsl_monte.h", has_type_id = false)]
	public struct MonteFunction
	{
		public MonteFunc f;
		public size_t dim;
		public void* params;
	}

	[Compact]
	[CCode (cname="gsl_monte_plain_state", cprefix="gsl_monte_plain_", cheader_filename="gsl/gsl_monte_plain.h")]
	public class MontePlainState
	{
		public size_t dim;
		public double* x;

		[CCode (cname="gsl_monte_plain_alloc")]
		public MontePlainState (size_t dim);
		public int init ();
		public static int integrate (MonteFunction* f, [CCode (array_length = false)] double[] xl, [CCode (array_length = false)] double[] xu, size_t dim, size_t calls,  RNG r, MontePlainState state, out double result, out double abserr);
	}

	[Compact]
	[CCode (cname="gsl_monte_miser_state", cprefix="gsl_monte_miser_", cheader_filename="gsl/gsl_monte_miser.h")]
	public class MonteMiserState
	{
		public size_t min_calls;
		public size_t min_calls_per_bisection;
		public double dither;
		public double estimate_frac;
		public double alpha;
		public size_t dim;
		public int estimate_style;
		public int depth;
		public int verbose;
		public double* x;
		public double* xmid;
		public double* sigma_l;
		public double* sigma_r;
		public double* fmax_l;
		public double* fmax_r;
		public double* fmin_l;
		public double* fmin_r;
		public double* fsum_l;
		public double* fsum_r;
		public double* fsum2_l;
		public double* fsum2_r;
		public size_t* hits_l;
		public size_t* hits_r;

		[CCode (cname="gsl_monte_miser_alloc")]
		public MonteMiserState (size_t dim);
		public int init ();
		public static int integrate (MonteFunction* f, [CCode (array_length = false)] double[] xl, [CCode (array_length = false)] double[] xh, size_t dim, size_t calls, RNG r, MonteMiserState state, out double result, out double abserr);
	}

	[Compact]
	[CCode (cname="gsl_monte_vegas_state", cprefix="gsl_monte_vegas_", cheader_filename="gsl/gsl_monte_vegas.h")]
	public class MonteVegasState
	{
		public size_t dim;
		public size_t bins_max;
		public uint bins;
		public uint boxes;
		public double* xi;
		public double* xin;
		public double* delx;
		public double* weight;
		public double vol;
		public double* x;
		public int* bin;
		public int* box;
		public double* d;
		public double alpha;
		public int mode;
		public int verbose;
		public uint iterations;
		public int stage;
		public double jac;
		public double wtd_int_sum;
		public double sum_wgts;
		public double chi_sum;
		public double chisq;
		public double result;
		public double sigma;
		public uint it_start;
		public uint it_num;
		public uint samples;
		public uint calls_per_box;
		public GLib.FileStream ostream;

		[CCode (cname="gsl_monte_vegas_alloc")]
		public MonteVegasState (size_t dim);
		public int init ();
		public static int integrate (MonteFunction* f, [CCode (array_length = false)] double[] xl, [CCode (array_length = false)] double[] xu, size_t dim, size_t calls, RNG r, MonteVegasState state, out double result, out double abserr);
	}


	/*
	 * Simulated Annealing
	 */
	[SimpleType]
	[CCode (cname="gsl_siman_params_t", cheader_filename="gsl/gsl_siman.h", has_type_id = false)]
	public struct SimanParams
	{
		public int n_tries;
		public int iters_fixed_T;
		public double step_size;
		public double k;
		public double t_initial;
		public double mu_t;
		public double t_min;
	}

	[CCode (lower_case_cprefix="gsl_siman_", cheader_filename="gsl/gsl_siman.h", has_type_id = false)]
	namespace Siman
	{
		[CCode (has_target = false)]
		public delegate double Efunc_t (void *xp);
		[CCode (has_target = false)]
		public delegate void step_t (RNG r, void *xp, double step_size);
		[CCode (has_target = false)]
		public delegate double metric_t (void *xp, void* yp);
		[CCode (has_target = false)]
		public delegate void print_t (void* xp);
		[CCode (has_target = false)]
		public delegate void copy_t (void* source, void* dest);
		[CCode (has_target = false)]
		public delegate void copy_construct_t (void* xp);
		[CCode (has_target = false)]
		public delegate void destroy_t (void* xp);

		public static void solve(RNG r, void *x0_p, Efunc_t Ef, step_t take_step, metric_t distance, print_t print_position, copy_t copyfunc, copy_construct_t copy_constructor, destroy_t destructor, size_t element_size, SimanParams params);
		public static void solve_many (RNG r, void *x0_p, Efunc_t Ef, step_t take_step, metric_t distance, print_t print_position, size_t element_size, SimanParams params);
	}


	/*
	 * Ordinary Differential Equations
	 */
	[CCode (cprefix="GSL_ODEIV_HADJ_", cheader_filename="gsl/gsl_odeiv.h", has_type_id = false)]
	public enum OdeivHadjustTypes
	{
		INC,
		NIL,
		DEC
	}

	[CCode (has_target = false)]
	public delegate int OdeivFunction (double t, [CCode (array_length = false)] double[] y, [CCode (array_length = false)] double[] dydt, void* params);
	[CCode (has_target = false)]
	public delegate int OdeivJacobian (double t, [CCode (array_length = false)] double[] y, [CCode (array_length = false)] double[] dfdy, [CCode (array_length = false)] double[] dfdt, void* params);
	[CCode (has_target = false)]
	public delegate void* OdeivStepAlloc (size_t dim);
	[CCode (has_target = false)]
	public delegate int OdeivStepApply (void* state, size_t dim, double t, double h, [CCode (array_length = false)] double[] y, [CCode (array_length = false)] double[] yerr, [CCode (array_length = false)] double[] dydt_in, [CCode (array_length = false)] double[] dydt_out, OdeivSystem* dydt);
	[CCode (has_target = false)]
	public delegate int OdeivStepReset (void* state, size_t dim);
	[CCode (has_target = false)]
	public delegate uint OdeivStepOrder (void* state);
	[CCode (has_target = false)]
	public delegate void OdeivStepFree (void* state);
	[CCode (has_target = false)]
	public delegate void* OdeivControlAlloc ();
	[CCode (has_target = false)]
	public delegate int OdeivControlInit (void* state, double eps_abs, double eps_rel, double a_y, double a_dydt);
	[CCode (has_target = false)]
	public delegate int OdeivControlHadjust (void* state, size_t dim, uint ord, [CCode (array_length = false)] double[] y, [CCode (array_length = false)] double[] yerr, [CCode (array_length = false)] double[] yp, [CCode (array_length = false)] double[] h);
	[CCode (has_target = false)]
	public delegate void OdeivControlFree (void* state);

	[SimpleType]
	[CCode (cname="gsl_odeiv_system", cheader_filename="gsl/gsl_odeiv.h", has_type_id = false)]
	public struct OdeivSystem
	{
		public OdeivFunction function;
		public OdeivJacobian jacobian;
		public size_t dimension;
		public void* params;
	}

	[SimpleType]
	[CCode (cname="gsl_odeiv_step_type", cheader_filename="gsl/gsl_odeiv.h", has_type_id = false)]
	public struct OdeivStepType
	{
		public string name;
		public int can_use_dydt_in;
		public int gives_exact_dydt_out;
		public OdeivStepAlloc alloc;
		public OdeivStepApply apply;
		public OdeivStepReset reset;
		public OdeivStepOrder order;
		public OdeivStepFree free;
	}

	[CCode (lower_case_cprefix="gsl_odeiv_step_", cheader_filename="gsl/gsl_odeiv.h")]
	namespace OdeivStepTypes
	{
		public static OdeivStepType* rk2;
		public static OdeivStepType* rk4;
		public static OdeivStepType* rkf45;
		public static OdeivStepType* rkck;
		public static OdeivStepType* rk8pd;
		public static OdeivStepType* rk2imp;
		public static OdeivStepType* rk2simp;
		public static OdeivStepType* rk4imp;
		public static OdeivStepType* bsimp;
		public static OdeivStepType* gear1;
		public static OdeivStepType* gear2;
	}

	[Compact]
	[CCode (cname="gsl_odeiv_step", cheader_filename="gsl/gsl_odeiv.h")]
	public class OdeivStep
	{
		public OdeivStepType* type;
		public size_t dimension;
		public void* state;

		[CCode (cname="gsl_odeiv_step_alloc")]
		public OdeivStep (OdeivStepType* T, size_t dim);
		public int reset ();
		public string name ();
		public uint order ();

		public int apply (double t, double h, [CCode (array_length = false)] double[] y, [CCode (array_length = false)] double[] yerr, [CCode (array_length = false)] double[] dydt_in, [CCode (array_length = false)] double[] dydt_out, OdeivSystem* dydt);
	}

	[SimpleType]
	[CCode (cname="gsl_odeiv_control_type", cheader_filename="gsl/gsl_odeiv.h", has_type_id = false)]
	public struct OdeivControlType
	{
		public string name;
		public OdeivControlAlloc alloc;
		public OdeivControlInit init;
		public OdeivControlHadjust hadjust;
		public OdeivControlFree free;
	}

	[Compact]
	[CCode (cname="gsl_odeiv_control", cheader_filename="gsl/gsl_odeiv.h")]
	public class OdeivControl
	{
		public OdeivControlType* type;
		public void* state;

		[CCode (cname="gsl_odeiv_control_alloc")]
		public OdeivControl (OdeivControlType* T);
		[CCode (cname="gsl_odeiv_control_standard_new")]
		public OdeivControl.standard (double eps_abs, double eps_rel, double a_y, double a_dydt);
		[CCode (cname="gsl_odeiv_control_y_new")]
		public OdeivControl.y (double eps_abs, double eps_rel);
		[CCode (cname="gsl_odeiv_control_yp_new")]
		public OdeivControl.yp (double eps_abs, double eps_rel);
		[CCode (cname="gsl_odeiv_control_scaled_new")]
		public OdeivControl.scaled (double eps_abs, double eps_rel, double a_y, double a_dydt, double[] scale_abs);

		public int init (double eps_abs, double eps_rel, double a_y, double a_dydt);
		public int hadjust (OdeivStep s, out double y, out double yerr, out double dydt, out double h);
		public string name ();
	}

	[Compact]
	[CCode (cname="gsl_odeiv_evolve", cheader_filename="gsl/gsl_odeiv.h")]
	public class OdeivEvolve
	{
		public size_t dimension;
		public double* y0;
		public double* yerr;
		public double* dydt_in;
		public double* dydt_out;
		public double last_step;
		public ulong count;
		public ulong failed_steps;

		[CCode (cname="gsl_odeiv_evolve_alloc")]
		public OdeivEvolve (size_t dim);
		public int apply (OdeivControl con, OdeivStep step, OdeivSystem* dydt, [CCode (array_length = false)] double[] t, double t1, [CCode (array_length = false)] double[] h, [CCode (array_length = false)] double[] y);
		public int reset ();
	}


	/*
	 * Interpolation
	 */
	[CCode (has_target = false)]
	public delegate void* InterpAlloc (size_t size);
	[CCode (has_target = false)]
	public delegate int InterpInit (void* t, [CCode (array_length = false)] double[] xa, [CCode (array_length = false)] double[] ya, size_t size);
	[CCode (has_target = false)]
	public delegate int InterpEval (void* t, [CCode (array_length = false)] double[] xa, [CCode (array_length = false)] double[] ya, size_t size, double x, InterpAccel* i, out double y);
	[CCode (has_target = false)]
	public delegate int InterpEvalDeriv (void* t, [CCode (array_length = false)] double[] xa, [CCode (array_length = false)] double[] ya, size_t size, double x, InterpAccel* i, out double y_p);
	[CCode (has_target = false)]
	public delegate int InterpEvalDeriv2 (void* t, [CCode (array_length = false)] double[] xa, [CCode (array_length = false)] double[] ya, size_t size, double x, InterpAccel* i, out double y_pp);
	[CCode (has_target = false)]
	public delegate int InterpEvalInteg (void* t, [CCode (array_length = false)] double[] xa, [CCode (array_length = false)] double[] ya, size_t size, InterpAccel* i, double a, double b, out double result);
	[CCode (has_target = false)]
	public delegate void InterpFree (void* t);

	[Compact]
	[CCode (cname="gsl_interp_accel", cheader_filename="gsl/gsl_interp.h")]
	public class InterpAccel
	{
		public size_t cache;
		public size_t miss_count;
		public size_t hit_count;

		[CCode (cname="gsl_interp_accel_alloc")]
		public InterpAccel ();
		public size_t find (double[] x_array, double x);
		public int reset ();
	}

	[SimpleType]
	[CCode (cname="gsl_interp_type", cheader_filename="gsl/gsl_interp.h", has_type_id = false)]
	public struct InterpType
	{
		public string name;
		public uint min_size;
		public InterpAlloc alloc;
		public InterpInit init;
		public InterpEval eval;
		public InterpEvalDeriv eval_deriv;
		public InterpEvalDeriv2 eval_deriv2;
		public InterpEvalInteg eval_integ;
		public InterpFree free;
	}

	[CCode (lower_case_cprefix="gsl_interp_", cheader_filename="gsl/gsl_interp.h")]
	namespace InterpTypes
	{
		public static InterpType* linear;
		public static InterpType* polynomial;
		public static InterpType* cspline;
		public static InterpType* cspline_periodic;
		public static InterpType* akima;
		public static InterpType* akima_periodic;
	}

	[Compact]
	[CCode (cname="gsl_interp", cheader_filename="gsl/gsl_interp.h")]
	public class Interp
	{
		InterpType* type;
		public double xmin;
		public double xmax;
		public size_t size;
		public void* state;

		[CCode (cname="gsl_interp_alloc")]
		public Interp (InterpType T, size_t n);
		public int init ([CCode (array_length = false)] double[] xa, [CCode (array_length = false)] double[] ya, size_t size);
		public string name ();
		public uint min_size ();
		public int eval_e ([CCode (array_length = false)] double[] xa, [CCode (array_length = false)] double[] ya, double x, InterpAccel a, out double y);
		public double eval ([CCode (array_length = false)] double[] xa, [CCode (array_length = false)] double[] ya, double x, InterpAccel a);
		public int eval_deriv_e ([CCode (array_length = false)] double[] xa, [CCode (array_length = false)] double[] ya, double x, InterpAccel a, out double d);
		public double eval_deriv ([CCode (array_length = false)] double[] xa, [CCode (array_length = false)] double[] ya, double x, InterpAccel a);
		public int eval_deriv2_e ([CCode (array_length = false)] double[] xa, [CCode (array_length = false)] double[] ya, double x, InterpAccel a, out double d2);
		public double eval_deriv2 ([CCode (array_length = false)] double[] xa, [CCode (array_length = false)] double[] ya, double x, InterpAccel a);
		public int eval_integ_e ([CCode (array_length = false)] double[] xa, [CCode (array_length = false)] double[] ya, double a, double b, InterpAccel acc, out double result);
		public double eval_integ ([CCode (array_length = false)] double[] xa, [CCode (array_length = false)] double[] ya, double a, double b, InterpAccel acc);
		public static size_t bsearch([CCode (array_length = false)] double[] x_array, double x, size_t index_lo, size_t index_hi);
	}

	[Compact]
	[CCode (cname="gsl_spline", cheader_filename="gsl/gsl_spline.h")]
	public class Spline
	{
		public Interp interp;
		public double* x;
		public double* y;
		public size_t size;

		[CCode (cname="gsl_spline_alloc")]
		public Spline (InterpType* T, size_t size);
		public int init ([CCode (array_length = false)] double[] xa, [CCode (array_length = false)] double[] ya, size_t size);
		public string name ();
		public uint min_size ();
		public int eval_e (double x, InterpAccel a, out double y);
		public double eval (double x, InterpAccel a);
		public int eval_deriv_e (double x, InterpAccel a, out double y);
		public double eval_deriv (double x, InterpAccel a);
		public int eval_deriv2_e (double x, InterpAccel a, out double y);
		public double eval_deriv2 (double x, InterpAccel a);
		public int eval_integ_e (double a, double b, InterpAccel acc, out double y);
		public double eval_integ (double a, double b, InterpAccel acc);
	}

	/*
	 * Numerical Differentiation
	 */
	[CCode (lower_case_cprefix="gsl_deriv_", cheader_fileame="gsl/gsl_deriv.h")]
	namespace Deriv
	{
		public static int central (Function* f, double x, double h, out double result, out double abserr);
		public static int backward (Function* f, double x, double h, out double result, out double abserr);
		public static int forward (Function* f, double x, double h, out double result, out double abserr);
	}


	/*
	 * Chebyshev Approximations
	 */
	[Compact]
	[CCode (cname="gsl_cheb_series", cprefix="gsl_cheb_", cheader_filename="gsl/gsl_chebyshev.h")]
	public class ChebSeries
	{
		public double* c;
		public size_t order;
		public double a;
		public double b;
		public size_t order_sp;
		public double *f;

		[CCode (cname="gsl_cheb_alloc")]
		public ChebSeries (size_t order);
		public int init (Function* func, double a, double b);
		public double eval (double x);
		public int eval_err (double x, out double result, out double abserr);
		public double eval_n (size_t order, double x);
		public int eval_n_err (size_t order, double x, out double result, out double abserr);
		public double eval_mode (double x, Mode mode);
		public int eval_mode_e (double x, Mode mode, out double result, out double abserr);
		public int calc_deriv (ChebSeries cs);
		public int calc_integ (ChebSeries cs);
	}


	/*
	 * Series Acceleration
	 */
	[Compact]
	[CCode (cname="gsl_sum_levin_u_workspace", free_function="gsl_sum_levin_u_free", cheader_filename="gsl/gsl_sum.h")]
	public class SumLevinUWorkspace
	{
		public size_t size;
		public size_t i;
		public size_t terms_used;
		public double sum_plain;
		public double* q_num;
		public double* q_den;
		public double* dq_num;
		public double* dq_den;
		public double* dsum;

		[CCode (cname="gsl_sum_levin_u_alloc")]
		public SumLevinUWorkspace (size_t n);
	}

	[CCode (lower_case_cprefix="gsl_sum_levin_u_", cheader_filename="gsl/gsl_sum.h")]
	namespace SumLevinU
	{
		public static int accel (double[] array, SumLevinUWorkspace w, out double sum_accel, out double abserr);
		public static int minmax (double[] array, size_t min_terms, size_t max_terms, SumLevinUWorkspace w, out double sum_accel, out double abserr);
		public static int step (double term, size_t n, size_t nmax, SumLevinUWorkspace w, out double sum_accel);
	}

	[Compact]
	[CCode (cname="gsl_sum_levin_utrunc_workspace", free_function="gsl_sum_levin_utrunc_free", cheader_filename="gsl/gsl_sum.h")]
	public class SumLevinUtruncWorkspace
	{
		public size_t size;
		public size_t i;
		public size_t terms_used;
		public double sum_plain;
		public double* q_num;
		public double* q_den;
		public double* dsum;

		[CCode (cname="gsl_sum_levin_utrunc_alloc")]
		public SumLevinUtruncWorkspace (size_t n);
	}

	[CCode (lower_case_cprefix="gsl_sum_levin_utrunc_", cheader_filename="gsl/gsl_sum.h")]
	namespace SumLevinUtrunc
	{
		public static int accel (double[] array, SumLevinUtruncWorkspace w, out double sum_accel, out double abserr_trunc);
		public static int minmax (double[] array, size_t min_terms, size_t max_terms, SumLevinUtruncWorkspace w, out double sum_accel, out double abserr_trunc);
		public static int step (double term, size_t n, SumLevinUtruncWorkspace w, out double sum_accel);
	}


	/*
	 * Wavelet Transforms
	 */
	[CCode (has_type_id = false)]
	public enum WaveletDirection
	{
		forward = 1,
		backward = -1
	}

	[CCode (has_target = false)]
	public delegate int WaveletInit (double** h1, double** g1, double** h2, double** g2, size_t* nc, size_t* offset, size_t member);

	[SimpleType]
	[CCode (cname="gsl_wavelet_type", cheader_filename="gsl/gsl_wavelet.h", has_type_id = false)]
	public struct WaveletType
	{
		public string name;
		public WaveletInit init;
	}

	[CCode (lower_case_cprefix="gsl_wavelet_", cheader_filename="gsl/gsl_wavelet.h")]
	namespace WaveletTypes
	{
		public static WaveletType* daubechies;
		public static WaveletType* daubechies_centered;
		public static WaveletType* haar;
		public static WaveletType* haar_centered;
		public static WaveletType* bspline;
		public static WaveletType* bspline_centered;
	}

	[Compact]
	[CCode (cname="gsl_wavelet_workspace", cheader_filename="gsl/gsl_wavelet.h")]
	public class WaveletWorkspace
	{
		public double* scratch;
		public size_t n;

		[CCode (cname="gsl_wavelet_workspace_alloc")]
		public WaveletWorkspace (size_t n);
	}

	[Compact]
	[CCode (cname="gsl_wavelet", cheader_filename="gsl/gsl_wavelet.h,gsl/gsl_wavelet2d.h")]
	public class Wavelet
	{
		public WaveletType* type;
		public double* h1;
		public double* g1;
		public double* h2;
		public double* g2;
		public size_t nc;
		public size_t offset;

		[CCode (cname="gsl_wavelet_alloc")]
		public Wavelet (WaveletType* T, size_t k);
		public string name ();
		public int transform ([CCode (array_length = false)] double[] data, size_t stride, size_t n, WaveletDirection dir, WaveletWorkspace work);
		public int transform_forward ([CCode (array_length = false)] double[] data, size_t stride, size_t n, WaveletWorkspace work);
		public int transform_inverse ([CCode (array_length = false)] double[] data, size_t stride, size_t n, WaveletWorkspace work);

		[CCode (cname="gsl_wavelet2d_transform")]
		public int transform_2d ([CCode (array_length = false)] double[] data, size_t tda, size_t size1, size_t size2, WaveletDirection dir, WaveletWorkspace work);
		[CCode (cname="gsl_wavelet2d_transform_forward")]
		public int transform_forward_2d ([CCode (array_length = false)] double[] data, size_t tda, size_t size1, size_t size2, WaveletWorkspace work);
		[CCode (cname="gsl_wavelet2d__transform_inverse")]
		public int transform_inverse_2d ([CCode (array_length = false)] double[] data, size_t tda, size_t size1, size_t size2, WaveletWorkspace work);
		[CCode (cprefix="gsl_wavelet2d_")]
		public int nstransform ([CCode (array_length = false)] double[] data, size_t tda, size_t size1, size_t size2, WaveletDirection dir,WaveletWorkspace work);
		[CCode (cprefix="gsl_wavelet2d_")]
		public int nstransform_forward ([CCode (array_length = false)] double[] data, size_t tda, size_t size1, size_t size2, WaveletWorkspace work);
		[CCode (cprefix="gsl_wavelet2d_")]
		public int nstransform_inverse ([CCode (array_length = false)] double[] data, size_t tda, size_t size1, size_t size2, WaveletWorkspace * work);
		[CCode (cprefix="gsl_wavelet2d_")]
		public int transform_matrix (Matrix a, WaveletDirection dir, WaveletWorkspace work);
		[CCode (cprefix="gsl_wavelet2d_")]
		public int transform_matrix_forward (Matrix a, WaveletWorkspace work);
		[CCode (cprefix="gsl_wavelet2d_")]
		public int transform_matrix_inverse (Matrix a, WaveletWorkspace work);
		[CCode (cprefix="gsl_wavelet2d_")]
		public int nstransform_matrix (Matrix a, WaveletDirection dir, WaveletWorkspace work);
		[CCode (cprefix="gsl_wavelet2d_")]
		public int nstransform_matrix_forward (Matrix a, WaveletWorkspace work);
		[CCode (cprefix="gsl_wavelet2d_")]
		public int nstransform_matrix_inverse (Matrix a, WaveletWorkspace work);
	}


	/*
	 * Discrete Hankel Transforms
	 */
	[Compact]
	[CCode (cname="gsl_dht", cheader_filename="gsl/gsl_dht.h")]
	public class DHT
	{
		public size_t size;
		public double nu;
		public double xmax;
		public double kmax;
		public double* j;
		public double* Jjj;
		public double* J2;

		[CCode (cname="gsl_dht_alloc")]
		public DHT (size_t size);
		[CCode (cname="gsl_dht_new")]
		public DHT.recalc (size_t size, double nu, double xmax);
		public int init (double nu, double xmax);
		public double x_sample (int n);
		public double k_sample (int n);
		public int apply ([CCode (array_length = false)] double[] f_in, [CCode (array_length = false)] double[] f_out);
	}


	/*
	 * One dimensional Root-Finding
	 */
	[CCode (has_target = false)]
	public delegate int RootFsolverSet (void* state, Function* f, double* root, double x_lower, double x_upper);
	[CCode (has_target = false)]
	public delegate int RootFsolverIterate (void* state, Function* f, double* root, double* x_lower, double* x_upper);
	[CCode (has_target = false)]
	public delegate int RootFdfsolverSet (void* state, FunctionFdf* f, double* root);
	[CCode (has_target = false)]
	public delegate int RootFdfsolverIterate (void* state, FunctionFdf* d, double* root);

	[SimpleType]
	[CCode (cname="gsl_root_fsolver_type", cheader_filename="gsl/gsl_roots.h", has_type_id = false)]
	public struct RootFsolverType
	{
		public string name;
		public size_t size;
		public RootFsolverSet @set;
		public RootFsolverIterate iterate;
	}

	[Compact]
	[CCode (cname="gsl_root_fsolver", cheader_filename="gsl/gsl_roots.h")]
	public class RootFsolver
	{
		public RootFsolverType* type;
		public Function* function;
		public double root;
		public double x_lower;
		public double x_upper;
		public void* state;

		[CCode (cname="gsl_root_fsolver_alloc")]
		public RootFsolver (RootFsolverType* T);
		public int @set (Function* f, double x_lower, double x_upper);
		public int iterate ();
		public unowned string name ();
	}

	[SimpleType]
	[CCode (cname="gsl_root_fdfsolver_type", cheader_filename="gsl/gsl_roots.h", has_type_id = false)]
	public struct RootFdfsolverType
	{
		public string name;
		public size_t size;
		public RootFdfsolverSet @set;
		public RootFdfsolverIterate iterate;
	}

	[Compact]
	[CCode (cname="gsl_root_fdfsolver", cheader_filename="gsl/gsl_roots.h")]
	public class RootFdfsolver
	{
		public RootFdfsolverType* type;
		public FunctionFdf* fdf;
		public double root;
		public void* state;

		[CCode (cname="gsl_root_fdfsolver_alloc")]
		public RootFdfsolver (RootFdfsolverType* T);
		public int @set (FunctionFdf* fdf, double root);
		public int iterate ();
		public unowned string name ();
	}

	[CCode (lower_case_cprefix="gsl_root_test_", cheader_filename="gsl/gsl_roots.h")]
	namespace RootTest
	{
		public static int interval (double x_lower, double x_upper, double epsabs, double epsrel);
		public static int residual (double f, double epsabs);
		public static int delta (double x1, double x0, double epsabs, double epsrel);
	}

	[CCode (lower_case_cprefix="gsl_root_fsolver_", cheader_filename="gsl/gsl_roots.h")]
	namespace RootFsolverTypes
	{
		public static RootFsolverType* bisection;
		public static RootFsolverType* brent;
		public static RootFsolverType* falsepos;
	}

	[CCode (lower_case_cprefix="gsl_root_fdfsolver_", cheader_filename="gsl/gsl_roots.h")]
	namespace RootFdfsolverTypes
	{
		public static RootFdfsolverType* newton;
		public static RootFdfsolverType* secant;
		public static RootFdfsolverType* steffenson;
	}


	/*
	 * One dimensional Minimization
	 */
	[CCode (has_target = false)]
	public delegate int MinSet (void* state, Function* f, double xminimun, double f_minimum, double x_lower, double f_lower, double x_upper, double f_upper);
	[CCode (has_target = false)]
	public delegate int MinIterate (void *state, Function* f, double* x_minimum, double* f_minimum, double* x_lower, double* f_lower, double* x_upper, double* f_upper);
	[CCode (has_target = false)]
	public delegate int MinBracketingFunction (Function* f, double* x_minimum, double* f_minimum, double* x_lower, double* f_lower, double* x_upper, double* f_upper, size_t eval_max);

	[SimpleType]
	[CCode (cname="gsl_min_fminimizer_type", cheader_filename="gsl/gsl_min.h", has_type_id = false)]
	public struct MinFminimizerType
	{
		public string name;
		public size_t size;
		public MinSet @set;
		public MinIterate iterate;
	}

	[Compact]
	[CCode (cname="gsl_min_fminimizer", cheader_filename="gsl/gsl_min.h")]
	public class MinFminimizer
	{
		public MinFminimizerType* type;
		public Function* function;
		public double x_minimum;
		public double x_lower;
		public double x_upper;
		public double f_minimum;
		public double f_lower;
		public double f_upper;
		public void* state;

		[CCode (cname="gsl_min_fminimizer_alloc")]
		public MinFminimizer (MinFminimizerType* T) ;
		public int @set (Function* f, double x_minimum, double x_lower, double x_upper);
		public int set_with_values (Function* f, double x_minimum, double f_minimum, double x_lower, double f_lower, double x_upper, double f_upper);
		public int iterate ();
		public unowned string name ();
	}

	[CCode (lower_case_cprefix="gsl_min_test_", cheader_filename="gsl/gsl_min.h")]
	namespace MinTest
	{
		public static int interval (double x_lower, double x_upper, double epsabs, double epsrel);
	}

	[CCode (lower_case_cprefix="gsl_min_fminimizer_", cheader_filename="gsl/gsl_min.h")]
	namespace MinFminimizerTypes
	{
		public static MinFminimizerType* goldensection;
		public static MinFminimizerType* brent;
	}

	[CCode (cname="gsl_min_find_bracket", cheader_filename="gsl/gsl_min.h")]
	public static int find_bracket (Function* f, double* x_minimum, double* f_minimum, double* x_lower, double* f_lower, double* x_upper, double* f_upper, size_t eval_max);


	/*
	 * Multidimensional Root-Finding
	 */
	[CCode (has_target = false)]
	public delegate int MultirootF (Vector x, void* params, Vector f);
	[CCode (has_target = false)]
	public delegate int MultirootFAlloc (void* state, size_t n);
	[CCode (has_target = false)]
	public delegate int MultirootFSet (void* state, MultirootFunction* function, Vector x, Vector f, Vector dx);
	[CCode (has_target = false)]
	public delegate int MultirootFIterate (void* state, MultirootFunction* function, Vector x, Vector f, Vector dx);
	[CCode (has_target = false)]
	public delegate void MultirootFFree (void* state);
	[CCode (has_target = false)]
	public delegate int MultirootDF (Vector x, void* params, Matrix df);
	[CCode (has_target = false)]
	public delegate int MultirootFDF (Vector x, void* params, Vector f, Matrix df);
	[CCode (has_target = false)]
	public delegate int MultirootFdfAlloc (void* state, size_t n);
	[CCode (has_target = false)]
	public delegate int MultirootFdfSet (void* state, MultirootFunctionFdf* fdf, Vector x, Vector f, Matrix J, Vector dx);
	[CCode (has_target = false)]
	public delegate int MultirootFdfIterate (void* state, MultirootFunctionFdf* fdf, Vector x, Vector f, Matrix J, Vector dx);
	[CCode (has_target = false)]
	public delegate int MultirootFdfFree (void* state);

	[SimpleType]
	[CCode (cname="gsl_multiroot_function", cheader_filename="gsl/gsl_multiroots.h", has_type_id = false)]
	public struct MultirootFunction
	{
		public MultirootF f;
		public size_t n;
		public void* params;
	}

	[CCode (cname="gsl_multiroot_fdjacobian", cheader_filename="gsl/gsl_multiroots.h")]
	public static int multiroot_fdjacobian (MultirootFunction* F, Vector x, Vector f, double epsrel, Matrix jacobian);

	[SimpleType]
	[CCode (cname="gsl_multiroot_fsolver_type", cheader_filename="gsl/gsl_multiroots.h", has_type_id = false)]
	public struct MultirootFsolverType
	{
		public string name;
		public size_t size;
		public MultirootFAlloc alloc;
		public MultirootFSet @set;
		public MultirootFIterate iterate;
		public MultirootFFree free;
	}

	[Compact]
	[CCode (cname="gsl_multiroot_fsolver", cheader_filename="gsl/gsl_multiroots.h")]
	public class MultirootFsolver
	{
		public MultirootFsolverType* type;
		public MultirootFunction* function;
		public Vector x;
		public Vector f;
		public Vector dx;
		public void* state;

		[CCode (cname="gsl_multiroot_fsolver_alloc")]
		public MultirootFsolver (MultirootFsolverType* T, size_t n);
		public int @set (MultirootFunction* f, Vector x);
		public int iterate ();
		public unowned string name ();
		public Vector root ();
	}

	[SimpleType]
	[CCode (cname="gsl_multiroot_function_fdf", cheader_filename="gsl/gsl_multiroots.h", has_type_id = false)]
	public struct MultirootFunctionFdf
	{
		public MultirootF f;
		public MultirootDF df;
		public MultirootFDF fdf;
		public size_t n;
		public void* params;
	}

	[SimpleType]
	[CCode (cname="gsl_multiroot_fdfsolver_type", cheader_filename="gsl/gsl_multiroots.h", has_type_id = false)]
	public struct MultirootFdfsolverType
	{
		public string name;
		public size_t size;
		public MultirootFdfAlloc alloc;
		public MultirootFdfSet @set;
		public MultirootFdfIterate iterate;
		public MultirootFdfFree free;
	}

	[Compact]
	[CCode (cname="gsl_multiroot_fdfsolver", cheader_filename="gsl/gsl_multiroots.h")]
	public class MultirootFdfsolver
	{
		public MultirootFdfsolverType* type;
		public MultirootFunctionFdf* fdf;
		public Vector x;
		public Vector f;
		public Matrix J;
		public Vector dx;
		public void* state;

		[CCode (cname="gsl_multiroot_fdfsolver_alloc")]
		public MultirootFdfsolver (MultirootFdfsolverType* T, size_t n);
		public int @set (MultirootFunctionFdf* fdf, Vector x);
		public int iterate ();
		public unowned string name ();
		public Vector root ();
	}

	[CCode (lower_case_cprefix="gsl_multiroot_test_", cheader_filename="gsl/gsl_multiroots.h")]
	namespace MultirootTest
	{
		public static int delta (Vector dx, Vector x, double epsabs, double epsrel);
		public static int residual (Vector f, double epsabs);
	}

	[CCode (lower_case_cprefix="gsl_multiroot_fsolver_", cheader_filename="gsl/gsl_multiroots.h")]
	namespace MultirootFsolverTypes
	{
		public static MultirootFsolverType* dnewton;
		public static MultirootFsolverType* broyden;
		public static MultirootFsolverType* hybrid;
		public static MultirootFsolverType* hybrids;
	}

	[CCode (lower_case_cprefix="gsl_multiroot_fdfsolver_", cheader_filename="gsl/gsl_multiroots.h")]
	namespace MultirootFdfsolverTypes
	{
		public static MultirootFdfsolverType* newton;
		public static MultirootFdfsolverType* gnewton;
		public static MultirootFdfsolverType* hybridj;
		public static MultirootFdfsolverType* hybridsj;
	}


	/*
	 * Multidimensional Minimization
	 */
	[CCode (has_target = false)]
	public delegate double MultiminF (Vector x, void* params);
	[CCode (has_target = false)]
	public delegate void MultiminDf (Vector x, void* params, Vector df);
	[CCode (has_target = false)]
	public delegate void MultiminFdf (Vector x, void* params, double* f, Vector df);
	[CCode (has_target = false)]
	public delegate int MultiminFAlloc (void *state, size_t n);
	[CCode (has_target = false)]
	public delegate int MultiminFSet (void* state, MultiminFunction* f, Vector x, double* size);
	[CCode (has_target = false)]
	public delegate int MultiminFIterate (void* state, MultiminFunction* f, Vector x, double* size, double* fval);
	[CCode (has_target = false)]
	public delegate int MultiminFFree (void* state);

	[SimpleType]
	[CCode (cname="gsl_multimin_function", cheader_filename="gsl/gsl_multimin.h", has_type_id = false)]
	public struct MultiminFunction
	{
		public MultiminF f;
		public size_t n;
		public void* params;
	}

	[SimpleType]
	[CCode (cname="gsl_multimin_function_fdf", cheader_filename="gsl/gsl_multimin.h", has_type_id = false)]
	public struct MultiminFunctionFdf
	{
		public MultiminF f;
		public MultiminDf df;
		public MultiminFdf fdf;
		public size_t n;
		public void* params;
	}

	[CCode (cname="gsl_multimin_diff", cheader_filename="gsl/gsl_multimin.h")]
	public static int multimin_diff (MultiminFunction* f, Vector x, Vector g);

	[SimpleType]
	[CCode (cname="gsl_multimin_fminimizer_type", cheader_filename="gsl/gsl_multimin.h", has_type_id = false)]
	public struct MultiminFminimizerType
	{
		public string name;
		public size_t size;
		public MultiminFAlloc alloc;
		public MultiminFSet @set;
		public MultiminFIterate iterate;
		public MultiminFFree free;
	}

	[Compact]
	[CCode (cname="gsl_multimin_fminimizer", cheader_filename="gsl/gsl_multimin.h")]
	public class MultiminFminimizer
	{
		public MultiminFminimizerType* type;
		public MultiminFunction* f;
		public double fval;
		public Vector x;
		public double size;
		public void* state;

		[CCode (cname="gsl_multimin_fminimizer_alloc")]
		public MultiminFminimizer (MultiminFminimizerType* T, size_t n);
		public int @set (MultiminFunction* f, Vector x, Vector step_size);
		public unowned string name ();
		public int iterate ();
		public double minimum ();
	}

	[CCode (lower_case_cprefix="gsl_multimin_test_", cheader_filename="gsl/gsl_multimin.h")]
	namespace MultiminTest
	{
		public static int gradient(Vector g, double epsabs);
		public static int size (double size, double epsabs);
	}

	[CCode (has_target = false)]
	public delegate int MultiminFdfAlloc (void *state, size_t n);
	[CCode (has_target = false)]
	public delegate int MultiminFdfSet (void* state, MultiminFunctionFdf* fdf, Vector x, double* f, Vector gradient, double step_size, double tol);
	[CCode (has_target = false)]
	public delegate int MultiminFdfIterate (void* state, MultiminFunctionFdf* fdf, Vector x, double* f, Vector gradient, Vector dx);
	[CCode (has_target = false)]
	public delegate int MultiminFdfRestart (void* state);
	[CCode (has_target = false)]
	public delegate int MultiminFdfFree (void* state);

	[SimpleType]
	[CCode (cname="gsl_multimin_fdfminimizer_type", cheader_filename="gsl/gsl_multimin.h", has_type_id = false)]
	public struct MultiminFdfminimizerType
	{
		public string name;
		public size_t size;
		public MultiminFdfAlloc alloc;
		public MultiminFdfSet @set;
		public MultiminFdfIterate iterate;
		public MultiminFdfRestart restart;
		public MultiminFdfFree free;
	}

	[Compact]
	[CCode (cname="gsl_multimin_fdfminimizer", cheader_filename="gsl/gsl_multimin.h")]
	public class MultiminFdfminimizer
	{
		public MultiminFdfminimizerType* type;
		public MultiminFunctionFdf* fdf;
		public double f;
		public Vector x;
		public Vector gradient;
		public Vector dx;
		public void* state;

		[CCode (cname="gsl_multimin_fdfminimizer_alloc")]
		public MultiminFdfminimizer (MultiminFdfminimizerType* T, size_t n);
		public int @set (MultiminFunctionFdf* fdf, Vector x, double step_size, double tol);
		public unowned string name ();
		public int iterate ();
		public int restart ();
		public double minimum ();
	}

	[CCode (lower_case_cprefix="gsl_multimin_fdfminimizer_", cheader_filename="gsl/gsl_multimin.h")]
	namespace MultiminFdfminimizerTypes
	{
		public static MultiminFdfminimizerType* steepest_descent;
		public static MultiminFdfminimizerType* conjugate_pr;
		public static MultiminFdfminimizerType* conjugate_fr;
		public static MultiminFdfminimizerType* vector_bfgs;
		public static MultiminFdfminimizerType* vector_bfgs2;
	}

	[CCode (lower_case_cprefix="gsl_multimin_fminimizer_", cheader_filename="gsl/gsl_multimin.h")]
	namespace MultiminFminimizerTypes
	{
		public static MultiminFminimizerType* nmsimplex;
	}


	/*
	 * Least-Squares Fitting
	 */
	[CCode (lower_case_cprefix="gsl_fit_", cheader_filename="gsl/gsl_fit.h")]
	namespace Fit
	{
		public static int linear ([CCode (array_length = false)] double[] x, size_t xstride, [CCode (array_length = false)] double[] y, size_t ystride, size_t n, out double c0, out double c1, out double cov00, out double cov01, out double cov11, out double sumsq);
		public static int wlinear ([CCode (array_length = false)] double[] x, size_t xstride, [CCode (array_length = false)] double[] w, size_t wstride, [CCode (array_length = false)] double[] y, size_t ystride, size_t n, out double c0, out double c1, out double cov00, out double cov01, out double cov11, double chisq);
		public static int linear_est (double x, double c0, double c1, double cov00, double cov01, double cov11, out double y, out double y_err);
		public static int mul ([CCode (array_length = false)] double[] x, size_t xstride, [CCode (array_length = false)] double[] y, size_t ystride, size_t n, out double c1, out double cov11, out double sumsq);
		public static int wmul ([CCode (array_length = false)] double[] x, size_t xstride, [CCode (array_length = false)] double[] w, size_t wstride, [CCode (array_length = false)] double[] y, size_t ystride, size_t n, out double c1, out double cov11, out double sumsq);
		public static int mul_est (double x, double c1, double cov11, out double y, out double y_err);
	}

	[Compact]
	[CCode (cname="gsl_multifit_linear_workspace", free_function="gsl_multifit_linear_free", cheader_filename="gsl/gsl_multifit.h")]
	public class MultifitLinearWorkspace
	{
		public size_t n;
		public size_t p;
		public Matrix A;
		public Matrix Q;
		public Matrix QSI;
		public Vector S;
		public Vector t;
		public Vector xt;
		public Vector D;

		[CCode (cname="gsl_multifit_linear_alloc")]
		public MultifitLinearWorkspace (size_t n, size_t p);
	}

	[CCode (lower_case_cprefix="gsl_multifit_", cheader_filename="gsl/gsl_multifit.h")]
	namespace Multifit
	{
		public static int linear (Matrix X, Vector y, Vector c, Matrix cov, out double chisq, MultifitLinearWorkspace work);
		public static int linear_svd (Matrix X, Vector y, double tol, out size_t rank, Vector c, Matrix cov, out double chisq, MultifitLinearWorkspace work);
		public static int wlinear (Matrix X, Vector w, Vector y, Vector c, Matrix cov, out double chisq, MultifitLinearWorkspace work);
		public static int wlinear_svd (Matrix X, Vector w, Vector y, double tol, out size_t rank, Vector c, Matrix cov, out double chisq, MultifitLinearWorkspace work);
		public static int linear_est (Vector x, Vector c, Matrix cov, out double y, out double y_err);
		public int linear_residuals (Matrix X, Vector y, Vector c, Vector r);
	}


	/*
	 * Nonlinear Least-Squares Fitting
	 */
	[CCode (has_target = false)]
	public delegate int MultifitF (Vector x, void* params, Vector f);
	[CCode (has_target = false)]
	public delegate int MultifitFAlloc (void* state, size_t n, size_t p);
	[CCode (has_target = false)]
	public delegate int MultifitFSet (void* state, MultifitFunction* function, Vector x, Vector f, Vector dx);
	[CCode (has_target = false)]
	public delegate int MultifitFIterate (void* state, MultifitFunction* function, Vector x, Vector f, Vector dx);
	[CCode (has_target = false)]
	public delegate void MultifitFFree (void* state);
	[CCode (has_target = false)]
	public delegate int MultifitDf (Vector x, void* params, Matrix df);
	[CCode (has_target = false)]
	public delegate int MultifitFdf (Vector x, void* params, Vector f, Matrix df);
	[CCode (has_target = false)]
	public delegate int MultifitFdfAlloc (void* state, size_t n, size_t p);
	[CCode (has_target = false)]
	public delegate int MultifitFdfSet (void* state, MultifitFunctionFdf fdf, Vector x, Vector f, Matrix J, Vector dx);
	[CCode (has_target = false)]
	public delegate int MultifitFdfIterate (void* state, MultifitFunctionFdf fdf, Vector x, Vector f, Matrix J, Vector dx);
	[CCode (has_target = false)]
	public delegate void MultifitFdfFree (void* state);

	[CCode (lower_case_cprefix="gsl_multifit_", cheader_filename="gsl/gsl_multifit_nlin.h")]
	namespace Multifit
	{
		public static int gradient (Matrix J, Vector f, Vector g);
		public static int covar (Matrix J, double epsrel, Matrix covar);
	}

	[SimpleType]
	[CCode (cname="gsl_multifit_function", cheader_filename="gls/gsl_multifit_nlin.h", has_type_id = false)]
	public struct MultifitFunction
	{
		public MultifitF f;
		public size_t n;
		public size_t p;
		public void* params;
	}

	[SimpleType]
	[CCode (cname="gsl_multifit_fsolver_type", cheader_filename="gsl/gsl_multifit_nlin.h", has_type_id = false)]
	public struct MultifitFsolverType
	{
		public string name;
		public size_t size;
		public MultifitFAlloc alloc;
		public MultifitFSet @set;
		public MultifitFIterate iterate;
		public MultifitFFree free;
	}

	[Compact]
	[CCode (cname="gsl_multifit_fsolver", cheader_filename="gsl/gsl_multifit_nlin.h")]
	public class MultifitFsolver
	{
		public MultifitFsolverType* type;
		public MultifitFunction* function;
		public Vector x;
		public Vector f;
		public Vector dx;
		public void* state;

		[CCode (cname="gsl_multifit_fsolver_alloc")]
		public MultifitFsolver (MultifitFsolverType* T,  size_t n, size_t p);
		public int @set (MultifitFunction* f, Vector x);
		public int iterate ();
		public unowned string name ();
		public Vector position ();
	}

	[SimpleType]
	[CCode (cname="gsl_multifit_function_fdf", cheader_filename="gsl/gsl_multifit_nlin.h", has_type_id = false)]
	public struct MultifitFunctionFdf
	{
		public MultifitF f;
		public MultifitDf df;
		public MultifitFdf fdf;
		public size_t n;
		public size_t p;
		public void* params;
	}

	[SimpleType]
	[CCode (cname="gsl_multifit_fdfsolver_type", cheader_filename="gsl/gsl_multifit_nlin.h", has_type_id = false)]
	public struct MultifitFdfsolverType
	{
		public string name;
		public size_t size;
		public MultifitFdfAlloc alloc;
		public MultifitFdfSet @set;
		public MultifitFdfIterate iterate;
		public MultifitFdfFree free;
	}

	[Compact]
	[CCode (cname="gsl_multifit_fdfsolver", cheader_filename="gsl/gsl_multifit_nlin.h")]
	public class MultifitFdfsolver
	{
		public MultifitFdfsolverType* type;
		public MultifitFunctionFdf* fdf;
		public Vector x;
		public Vector f;
		public Vector J;
		public Vector dx;
		public void* state;

		[CCode (cname="gsl_multifit_fdfsolver_alloc")]
		public MultifitFdfsolver (MultifitFdfsolverType* T, size_t n, size_t p);
		public int @set (MultifitFunctionFdf* fdf, Vector x);
		public int iterate ();
		public unowned string name ();
		public Vector position ();
	}

	[CCode (lower_case_cprefix="gsl_multifit_test_", cheader_filename="gsl/gsl_multifit_nlin.h")]
	namespace MultifitTest
	{
		public static int delta (Vector dx, Vector x, double epsabs, double epsrel);
		public static int gradient (Vector g, double epsabs);
	}

	[CCode (lower_case_cprefix="gsl_multifit_fdfsolver_", cheader_filename="gsl/gsl_multifit_nlin.h")]
	namespace MultifitFdfsolverTypes
	{
		public static MultifitFdfsolverType* lmder;
		public static MultifitFdfsolverType* lmsder;
	}


	/*
	 * Basis Splines
	 */
	[Compact]
	[CCode (cname="gsl_bspline_workspace", cprefix="gsl_bspline_", cheader_filename="gsl/gsl_bspline.h")]
	public class BsplineWorkspace
	{
		public size_t k;
		public size_t km1;
		public size_t l;
		public size_t nbreak;
		public size_t n;
		public Vector knots;
		public Vector deltal;
		public Vector deltar;
		public Vector B;

		[CCode (cname="gsl_bspline_alloc")]
		public BsplineWorkspace (size_t k, size_t nbreak);
		public size_t ncoeffs ();
		public size_t order ();
		[CCode (instance_pos=-1)]
		public double breakpoint (size_t i);
		[CCode (instance_pos=-1)]
		public int knots_uniform (double a, double b);
		[CCode (instance_pos=-1)]
		public int eval (double x, Vector B);
	}
}

