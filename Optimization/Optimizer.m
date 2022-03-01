% Code for finding optimum values of T/W, and W/S which gives minimum weight
% with all constraints satisfied.
clear
clc
close all

global Aircraft
Aircraft = struct();

d2r = pi/180;

% number of variables: 6
% Design variables order: T/W, Sweep_Quater_Chord, t/c root,
% cruising altitude, A, S.

LB = [0.158 , 23, 0.11, 20000,8.98,0.195,800,0.7];  % Lower Bound
UB = [0.266, 42, 0.14, 35000, 10.85,0.345,3500,0.85]; % Upper Bound
%LB = [0.158 , 1.9, 0.11, 10000,8.98, 85.95,0];  % Lower Bound
%UB = [0.266, 3.5, 0.15, 30000, 10.85,200,19]; % Upper Bound

A = [];
B = [];
Aeq = [];
Beq = [];

x0 = [0.19,27,0.13,27000,9.91,0.21,2210,0.75]; % Starting Point

options = optimoptions('fmincon','Algorithm','sqp','Display','iter-detailed',...
    'FunctionTolerance',1e-6,'OptimalityTolerance',1e-6,'ConstraintTolerance',1e-6,....
    'StepTolerance',1e-20,'MaxFunctionEvaluations',500,'MaxIterations',1000);
% x=Obj_Func(x0);
% disp(x);
[X,~,exitflag,output]= fmincon(@(x) Obj_Func(x), x0, A, B, Aeq, Beq, LB, UB, @(x) Nonlincon(x),options);
%disp(x);
%%%%% Ratios for comparison %%%%%
Aircraft.ratios.Wing_We=Aircraft.Weight.wing/Aircraft.Weight.empty_weight;
Aircraft.ratios.Wing_Wto=Aircraft.Weight.wing/Aircraft.Weight.MTOW;

Aircraft.ratios.Fuselage_We=Aircraft.Weight.fuselage/Aircraft.Weight.empty_weight;
Aircraft.ratios.Fuselage_Wto=Aircraft.Weight.fuselage/Aircraft.Weight.MTOW;


