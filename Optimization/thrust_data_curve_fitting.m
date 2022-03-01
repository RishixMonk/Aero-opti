%%% Scripting for fitting a surface to the power data

clear; clc; close all;

X = dlmread('thurst_data.csv');

alt = [ 0 * ones(17,1) ; 10000 * ones(17,1); 20000 * ones(17,1); 30000 * ones(17,1) ; 40000 * ones(17,1)  ] ;

speed = X(:,1);

SHP = X(:,2);

fitobject = fit([alt,speed], SHP, 'poly24')
plot(fitobject,[alt,speed],SHP)

