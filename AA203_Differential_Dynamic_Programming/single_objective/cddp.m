clc; clear all; clear figure;
global N n m Quu_all Qux_all Qu_all mu1 mu2 ...
    f fx fu l lx lxx lu luu lux lf lfx lfxx g gx gu;

n = 2; %dimension of states
m = 2; %dimension of controls
mu1 = 0.1;
mu2 = 0.1;

plot_init = true;

%Load functions
load('model.mat','L','x0','x_goal','f','fx','fu','l','lx','lxx','lu','luu', ...
    'lux','lf','lfx','lfxx','g','gx','gu','holes','radius')

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Define state and control
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

N = 50; % Time horizon

% state history
state = zeros(N,2); %[x,y]

% control history
% controls just represent the delta x and y
control = zeros(N-1,2); %[vx,vy]=[dx/dt,dy/dt]

% Initialize everything
Quu_all = cell(N,1);
Qux_all = cell(N,1);
Qu_all = cell(N,1);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Initialize nominal trajectory
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
state(1,:) = x0';
k=1;
while state(k,2)<L
    k = k+1;
    state(k,:) = [1,k];
    control(k-1,:) = [0,1];
end
while state(k,1)<L
    k = k+1;
    state(k,:) = [state(k-1,1)+1,state(k-1,2)];
    control(k-1,:) = [1,0];
end

while k<N
    k = k+1;
    state(k,:) = [L,L];
    control(k,:) = [0,0];
end

if plot_init==true
    t = linspace(0,2*pi,500);
    figure;hold on;
    plot(state(:,1), state(:,2),'b','LineWidth',2);
    for h=1:length(holes)
        center = holes(h,:);
        rad = radius(h);
        cx = center(1)+rad*cos(t);
        cy = center(2)+rad*sin(t);
        plot(cx,cy);
    end 
    axis([0 L+1 0 L+1]);
    xlabel('x');
    ylabel('y');
    grid on;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Run CDDP
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

n_iter = 20;
plots = [];
costs = J(state,control);
b_times = [];
f_times = [];
total_times = [];
for it=1:n_iter
    disp(strcat('iteration ',num2str(it)));
    tic;
    backward_pass(state,control);
    tt1 = toc;
    b_times = [b_times;tt1];
    disp('End of backward pass');
    tic;
    [state, control, J_temp] = forward_pass(state,control);
    tt2 = toc;
    f_times = [f_times;tt2];
    costs = [costs; J_temp];
    p = plot(state(:,1), state(:,2),'r','LineWidth',2);
    hold on;
    plots = [plots,p];
    alpha(plots(it),it/n_iter);
    total_times = [total_times; tt1+tt2];
end

figure;
plot(0:n_iter, costs, 'LineWidth', 2);
xlabel('iteration');
ylabel('cost');
title('Evolution of total cost');

figure;
hold on;
plot(1:n_iter,b_times, 'LineWidth', 2);
plot(1:n_iter,f_times,'LineWidth',2);
xlabel('iteration');
ylabel('time');
legend('backward pass','forward pass');
title('Evolution of passes computation times');
