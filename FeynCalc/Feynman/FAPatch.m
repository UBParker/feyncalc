(* ::Package:: *)

(* ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ *)

(* :Title: FAPatch															*)

(*
	This software is covered by the GNU General Public License 3.
	Copyright (C) 1990-2016 Rolf Mertig
	Copyright (C) 1997-2016 Frederik Orellana
	Copyright (C) 2014-2016 Vladyslav Shtabovenko
*)

(* :Summary:  Patch for FeynArts										    *)

(* ------------------------------------------------------------------------ *)

FAPatch::usage =
"If an unpatched copy of FeynArts is present in $FeynArtsDirectory, \
evaluating FAPatch causes the files making up FeynArts to be modified in \
order for FeynArts to be compatible with FeynCalc.";

PatchModelsOnly::usage =
"PatchModelsOnly is an Option of FAPatch. When set to True, FAPatch will patch \
only the model files in the Models directory of the FeynArts installation. This \
is useful when you have added new custom models, e.g. generated by FeynRules.";

FCFilePatch::usage =
"FCFilePatch[input,output, rp] replaces the patterns given by rp in the file input \
and writes the modified version to output. rp should be a list of the form \
{string -> string, ..}.";

FAPatch::incomplete =
"Your installation of FeynArts appears to be incomplete. Patching aborted.";

FAPatch::old =
"Your version of FeynArts is too old to be patched. Patching aborted.";

FAPatch::already =
"Your version of FeynArts is already patched. Patching aborted.";

(* ------------------------------------------------------------------------ *)

Begin["`Package`"]
End[]

Begin["`FAPatch`Private`"]

FCFilePatch[input_String, output_String, replacements_List] :=
	Block[{tmp, res},
		tmp = Import[input, "Text"] <> "\n";

		If[	!StringMatchQ[tmp, "*Patched for use with FeynCalc*", IgnoreCase -> True],
			res = StringReplace[tmp, replacements, MetaCharacters -> Automatic];
			res = StringJoin[{"(* Patched for use with FeynCalc *)\n",res}],
			res = tmp
		];

		Export[output, res, "Text"];
	];



Options[FAPatch] = {
	PatchModelsOnly -> False,
	Replace -> {
		"FourVector" -> "FAFourVector",
		"DiracSpinor" -> "FADiracSpinor",
		"DiracSlash" -> "FADiracSlash",
		"DiracMatrix" -> "FADiracMatrix",
		"DiracTrace" -> "FADiracTrace",
		"MetricTensor" -> "FAMetricTensor",
		"ScalarProduct" -> "FAScalarProduct",
		"ChiralityProjector" -> "FAChiralityProjector",
		"GS" -> "FAGS",
		"SUNT" -> "FASUNT",
		"SUNF" -> "FASUNF",
		"LeviCivita" -> "FALeviCivita",
		"Loop" -> "FALoop",
		"NonCommutative" -> "FANonCommutative",
		"PolarizationVector" -> "FAPolarizationVector",
		"FeynAmp" -> "FAFeynAmp",
		"PropagatorDenominator" -> "FAPropagatorDenominator",
		"GaugeXi" -> "FAGaugeXi",
		"FeynAmpDenominator" -> "FAFeynAmpDenominator",
		"FeynAmpList" -> "FAFeynAmpList",
		"ME" -> "FCGV[\"ME\"]",
		"MM" -> "FCGV[\"MM\"]",
		"ML" -> "FCGV[\"ML\"]",
		"MU" -> "FCGV[\"MU\"]",
		"MD" -> "FCGV[\"MD\"]",
		"MC" -> "FCGV[\"MC\"]",
		"MS" -> "FCGV[\"MS\"]",
		"MT" -> "FCGV[\"MT\"]",
		"MB" -> "FCGV[\"MB\"]",
		"MH" -> "FCGV[\"MH\"]",
		"MZ" -> "FCGV[\"MZ\"]",
		"MW" -> "FCGV[\"MW\"]",
		"EL" -> "FCGV[\"EL\"]",
		"CW" -> "FCGV[\"CW\"]",
		"SW" -> "FCGV[\"SW\"]"
	}
};

FAPatch[OptionsPattern[]] :=
	Block[{repList, feynartsFile, allfiles,filenames},

		repList = Map[{
			Rule[RegularExpression["\\b" <> First[#] <> "\\b"], Last[#]],
			Rule[RegularExpression["\\_" <> First[#] <> "\\b"],"_" <> Last[#]],
			Rule[RegularExpression[First[#] <> "\\_\\b"], Last[#] <> "_"]
		} &, OptionValue[Replace]] // Flatten;

		repList = Join[
			{"by Hagen Eck, Sepp Kueblbeck, and Thomas Hahn" ->
			"(patched for use with FeynCalc) by Hagen Eck, Sepp Kueblbeck, and Thomas Hahn"},
			repList];

		If[	FileNames["FeynArts.m", $FeynArtsDirectory] === {} ||
			FileNames["*", FileNameJoin[{$FeynArtsDirectory, "FeynArts"}]] === {} ||
			FileNames["*", FileNameJoin[{$FeynArtsDirectory, "Models"}]] === {},
			Message[FAPatch::incomplete];
			Abort[]
		];

		feynartsFile = Import[ToFileName[{$FeynArtsDirectory}, "FeynArts.m"], "Text"];

		(*	Check the FeynArts version	*)
		If[	First[StringCases[feynartsFile, "$FeynArts = " ~~ x : NumberString ~~ "\n" :> x]] < 3.,
			Message[FAPatch::old];
			Abort[]
		];

		If[ !OptionValue[PatchModelsOnly],
			(*	Check if already patched	*)
			If[	StringMatchQ[feynartsFile, "*patched for use with FeynCalc*", IgnoreCase -> True],
				Message[FAPatch::already];
				Abort[]
			];
		];

		If[ !OptionValue[PatchModelsOnly],
			filenames = Flatten[{
				FileNames[{"*.m"}, FileNameJoin[{$FeynArtsDirectory}]],
				FileNames[{"*.mod", "*.gen"}, FileNameJoin[{$FeynArtsDirectory, "Models"}], Infinity],
				FileNames[{"*.m", "*.m-ok"}, FileNameJoin[{$FeynArtsDirectory, "FeynArts"}]]}
			],
			filenames = FileNames[{"*.mod", "*.gen"}, FileNameJoin[{$FeynArtsDirectory, "Models"}], Infinity]
		];


		(* Prepare the list of files to be patched *)
		allfiles = Map[
			If[FileNameTake[FileInformation[#, "AbsoluteFileName"]] === FileNameTake[#], #, Unevaluated@Sequence[]] &,
			filenames
		];

		If[ !OptionValue[PatchModelsOnly],

			If[	ChoiceDialog["An installation of FeynArts has been found in \"" <> $FeynArtsDirectory <>
				"\". This program will now patch FeynArts to allow interoperation with FeynCalc. Continue?"],
					(* The actual patching *)
					WriteString["stdout","Patching FeynArts..."];
					Map[FCFilePatch[#, #, repList] &, allfiles];
					WriteString["stdout"," done!\n"],
					WriteString["stdout","Patching aborted, no files were changed.\n"];
					Return[]
			],

			WriteString["stdout","Patching FeynArts models..."];
			Map[FCFilePatch[#, #, repList] &, allfiles];
			WriteString["stdout"," done!\n"]
		]
	];




		(* The following changes were done in old FAPatch.m. Currently they are not applied. *)
		(*
				in  Setup.m

			"\nP$Generic = Flatten[P$Generic | Phi`Objects`$ParticleHeads];\n
			If[ Phi`Objects`$FermionHeads=!=None,\n
			P$NonCommuting=Flatten[P$NonCommuting | Phi`Objects`$FermionHeads]];"

				in Analytic.m (small fixes?)

		"SequenceForm[StringTake[ToString[type], 3]" ->
		"SequenceForm[StringTake[ToString[type],Min[3,StringLength[ToString[type]]]]"

		"Cases[p, PropagatorDenominator[__]]" ->
		"Cases[p, HoldPattern[PropagatorDenominator[__]]]"

				in Insert.m (allow one-vertices?)

		"DeleteCases[Take[#, 2], Vertex[1, ___][_]]&/@ top," ->
		"(DeleteCases[Take[#,2],Vertex[1][_]]&/@(top/.p:Propagator[Internal][___,Vertex[1,___][_],___]:>(p/.Vertex[1]->Vertex[vertexone])))/.vertexone -> 1,"

		"MapIndexed[ Append[#1, Field@@ #2]&, top" ->
		"MapIndexed[Append[#1,Field@@#2]&,Sort[Sort[Take[#,2]]&/@ top/. {Incoming->AAA,Outgoing->AAB}]/. {AAA->Incoming,AAB->Outgoing}"

				in Utilities.m (allow one-vertices?)

		"Union[ Cases[top, Vertex[n__][_] /; {n} =!= {1}, {2}] ]" ->
		"Union[Join[Cases[Cases[top,Propagator[Internal][__]],Vertex[n__][_],Infinity],Cases[top,Vertex[n__][_]/;{n}=!={1},{2}]]]"

				in Graphics.m (small fixes?)

		"Orientation[ p1_, p2_ ] := N[ArcTan@@ (p2 - p1)]" ->
		"Orientation[ p1_, p2_ ] := N[(If[{##}=={0,0},0,ArcTan[##]]&)@@ (p2 - p1)]"

		*)

FCPrint[1, "FAPatch.m loaded"];
End[];



