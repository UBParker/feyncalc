(* ::Package:: *)

(* :Title: QEDOnePhotonTadpoleOneLoop                                       *)

(*
	This software is covered by the GNU General Public License 3.
	Copyright (C) 1990-2016 Rolf Mertig
	Copyright (C) 1997-2016 Frederik Orellana
	Copyright (C) 2014-2016 Vladyslav Shtabovenko
*)

(* :Summary:  Computation of the 1-photon tadpole diagram in QED at 1-loop  *)

(* ------------------------------------------------------------------------ *)


(* ::Section:: *)
(*The 1-photon tadpole in QED*)


(* ::Subsection:: *)
(*Load FeynCalc, FeynArts and Tarcer*)


If[ $FrontEnd === Null,
		$FeynCalcStartupMessages = False;
		Print["Computation of the 1-photon tadpole diagram in QED at 1-loop"];
];
$LoadFeynArts=True;
<< FeynCalc`
$FAVerbose=0;


(* ::Subsection:: *)
(*Generate Feynman diagrams*)


Paint[diags = InsertFields[CreateTopologies[1, 1 -> 0 ], {V[1]} -> {},
		InsertionLevel -> {Particles}, GenericModel -> "Lorentz",
		ExcludeParticles->{S[1],S[2],S[3],V[2],V[3],F[3],F[4],
		U[1],U[2],U[3],U[4],F[2,{2}],F[2,{3}]}], ColumnsXRows -> {1, 1},
		SheetHeader -> False,   Numbering -> None,SheetHeader->None,ImageSize->{256,256}];


(* ::Text:: *)
(*Notice that we choose the prefactor to be 1/(2^D)*(Pi)^(D/2). This is because the 1/Pi^(D/2) piece of the general prefactor 1/(2Pi)^D goes into the definition of the loop integrals using Tarcer's notation.*)


amps = FCFAConvert[CreateFeynAmp[diags, Truncated -> True,GaugeRules->{},PreFactor->1/((2^D)*(Pi)^(D/2))],
IncomingMomenta->{k},LoopMomenta->{q},UndoChiralSplittings->True,ChangeDimension->D,List->False,SMP->True];


(* ::Text:: *)
(*We obtain three tadpole diagrams. Having performed the Dirac algebra we clearly see that these diagrams must vanish because the loop integrals are antisymmetric under q^mu -> - q^mu.*)


ampsEval=(ChangeDimension[amps,D]//Contract//DiracSimplify)/.{DiracTrace->Tr}


(* ::Text:: *)
(*FeynCalc's tensor integral decomposition function TID can recognize that.*)


onePhotonTadpoleFinal = ampsEval//TID[#,q]&


Print["The 1-photon tadpole diagrams in QED vanish: ",
			If[Simplify[onePhotonTadpoleFinal]===0, "CORRECT.", "!!! WRONG !!!"]];
