%%% Scripting for fitting a surface to the power data

clear; clc; close all;

X = dlmread('esfc_data.csv');

alt = [ 0 * ones(17,1) ; 10000 * ones(17,1); 20000 * ones(17,1); 36089 * ones(17,1)  ] ;

speed = X(:,1);

esfc = X(:,2);

fitobject = fit([alt,speed], esfc, 'poly25')
plot(fitobject,[alt,speed],esfc)

