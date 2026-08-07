% time profiler for the GUI
clear all; close all; clc;
profile on
Assist_Shortening_GUI_exported();
pause(60); % let the GUI run for one minute
profile off
profile viewer