%% 基于蒙特卡洛方法的机载SAR图像几何定位误差仿真研究
%% 探讨位置、速度和斜距对距离向和方位向定位精度的影响
close all;
clc; clear;
% 输入参数： 两载机方位角 载机速度分布 载机三维位置分布 斜距分布 多普勒参数分布 目标高程分布;
% 已经知参数： 目标平面位置（0,0,0）;
% 输出： 估计的目标位置均值（期望值\mu），目标位置分布标准差（\fa）;
% 后续考虑的影响因素：地球椭球弯曲 对流层延迟;
% 使用LM算法迭代解算方程数值解，三维场景, 在ENU坐标系下;


NSim = 10000;      % 仿真次数

% 载机1
a1.h_a_dm = 15000; % 飞行高度 m
a1.h_t = 0;        % 目标高程 m
% a1.R_dm = 100000;   % 斜距 slant m
a1.f_dc = 0;       % 多普勒中心频率 Hz
a1.lambda = 0.21;  % 波长 m
a1.target = [0 0]; % 目标位置
a1.speed =  250;    % 速度
a1.azimuth = 0;    % 方位角


% 初始化结构体数组来保存结果
simulationResults = struct('PositionMu', {}, 'PositionSigma', {});

% for R_index = 1:3
for R_index = 1:18
    R_values = 30000:10000:200000; % 斜距 slant m
    a1.R_dm = R_values(R_index);
    % a1.R_dm = R_values;
    [a1.x_t, a1.y_t, a1.v_e, a1.v_n] = airplanePVTrans(a1.azimuth, a1.speed, a1.R_dm, a1.h_a_dm);
    
    % 组合导航系统参数精度参考SIN-INS-1000光纤惯性导航系统（正弦波测控公司）
    % for Error=0:10
    PosSysError = [0,0,0];
    PosRandomError = [1.5,1.5,1.5];
    VelSysError = [0,0,0];
    velRandomError = [0.0,0.0,0.0];
    a1.x_t_Nor = normrnd(a1.x_t+PosSysError(1),PosRandomError(1),[NSim 1]);    % 飞机东向位置
    a1.y_t_Nor = normrnd(a1.y_t+PosSysError(2),PosRandomError(2),[NSim 1]);    % 飞机北向位置
    a1.h_a_Nor = normrnd(a1.h_a_dm+PosSysError(3),PosRandomError(3),[NSim 1]); % 飞行高度 m
    a1.h_t_Nor = normrnd(a1.h_t,5,[NSim 1]);                                   % 目标高程 m
    a1.v_e_Nor = normrnd(a1.v_e+VelSysError(1),velRandomError(1),[NSim 1]);    % m/s
    a1.v_n_Nor = normrnd(a1.v_n+VelSysError(2),velRandomError(2),[NSim 1]);    % m/s
    a1.v_u_Nor = normrnd(0+VelSysError(3),     velRandomError(3),[NSim 1]);    % m/s
    a1.R_Nor = normrnd(a1.R_dm,1,[NSim 1]);                                    % 斜距 slant m
    a1.f_dc_Nor = normrnd(0,0.2,[NSim 1]);                                     % 多普勒中心频率 Hz
    
    simResult = zeros([NSim 2]);              % 存储仿真结果
    parfor i=1:NSim                           % 执行定位仿真
        h = a1.h_a_Nor(i,1) - a1.h_t_Nor(i,1);            % 相对高程差
        sv = -a1.f_dc_Nor(i,1)*a1.lambda*a1.R_Nor(i,1)/2; % 
        f = @(x)[
            ((a1.x_t_Nor(i,1)-x(1))^2+(a1.y_t_Nor(i,1)-x(2))^2+h^2-a1.R_Nor(i,1)^2),
            (a1.v_e_Nor(i,1)*(a1.x_t_Nor(i,1)-x(1)) + a1.v_n_Nor(i,1)*(a1.y_t_Nor(i,1)-x(2)) + a1.v_u_Nor(i,1)*h+sv)];
        x2d = fsolve(f,[1000, -1000],optimset('Algorithm','levenberg-marquardt'));          % 解算得
        simResult(i,:) = x2d(1,:);
    end
    
    % PositionMu(Error+1,:) = mean(simResult,1);
    % PositionSigma(Error+1,:) = std(simResult,1);
    
    % 存储仿真结果的均值和方差
    PositionMu(R_index,:) = mean(simResult,1);
    PositionSigma(R_index,:) = std(simResult,1);

    % end
    
    % figure();
    % scatter(simResult(:,1),simResult(:,2),'.');
    % hold on;
    % scatter(0,0,'+','LineWidth',2);
    % axis equal;
    % box on;
    % grid on;
    % hold off;

    % 保存当前仿真结果
    simulationResults(1).PositionMu = PositionMu;
    simulationResults(1).PositionSigma = PositionSigma;
end


%% 

% 保存结果到MAT文件
filePath = 'SlantRangeErrorU_simulation_results_velocityTest1.mat';
save(filePath, 'simulationResults');


%%
filePath = 'SlantRangeErrorU_simulation_results_velocityTest1.mat';
load(filePath);  % 加载仿真结果

figure;
hold on;
% grid on;  % 开启网格
box on;
% 定义不同仿真条件下的线型和颜色
lineStyles = {'-o', '-+', '-^'};
colors = {[0 0.4470 0.7410], [0.8500 0.3250 0.0980], [0.9290 0.6940 0.1250]};  % MATLAB默认颜色

% 循环遍历每个仿真结果并绘图
for i = 1:length(simulationResults)
    PositionMu = simulationResults(i).PositionMu;
    PositionSigma = simulationResults(i).PositionSigma;
    
    % 计算总RMSE
    totalRMSE = sqrt(PositionSigma(:,1).^2 + PositionSigma(:,2).^2);
    AzimuthRMSE =  PositionSigma(:,1);
    RangeRMSE =  PositionSigma(:,2);
    % 绘制曲线
    plot(30:10:200, totalRMSE, lineStyles{1}, 'LineWidth', 1.5, 'Color', colors{1}, 'MarkerSize', 8);
    plot(30:10:200, AzimuthRMSE, lineStyles{2}, 'LineWidth', 1.5, 'Color', colors{2}, 'MarkerSize', 8);
    plot(30:10:200, RangeRMSE, lineStyles{3}, 'LineWidth', 1.5, 'Color', colors{3}, 'MarkerSize', 8);
end

% 添加图例
legend('Positon RMSE', 'Azimuth RMSE', 'Range RMSE', 'Location', 'northwest');

% 添加轴标签和标题
xlabel('Slant Range (km)');
ylabel('Position Root Mean Square Error (m)');
% title('SAR Positioning Uncertainty vs. Slant Range', 'Interpreter', 'latex');
% xlim([30,200]);
ylim([0,45]);

% 设置字体和边框
set(gca,'FontWeight', 'bold');
set(gca, 'LooseInset', [0,0,0,0]);
set(gca,'linewidth',1.5);
set(gca,'FontSize',12);
% 设置图形尺寸和分辨率
set(gcf,'Units','Inches');
pos = get(gcf,'Position');
set(gcf,'PaperPositionMode','Auto','PaperUnits','Inches','PaperSize',[7, 5.5]);
% 设置坐标轴颜色为黑色
set(gca,'xcolor','k');
set(gca,'ycolor','k');
grid on;

% 获取当前坐标区并修改网格线样式
ax = gca;
ax.GridLineStyle = '--';       % 设置为虚线
ax.GridColor = [0.5 0.5 0.5];  % 灰色（RGB值范围[0,1]）
ax.GridAlpha = 1;              % 不透明度（0=透明，1=不透明）
% 导出图形
% exportgraphics(gca,'SARPositioningUncertainty_vs_SlantRange.pdf');
print('SARPositioningUncertainty_vs_SlantRange_velocityTest1','-dpdf','-bestfit')


%%
% figure();
% scatter(simResult(:,1),simResult(:,2),'.');
% hold on;
% scatter(0,0,'+','LineWidth',2);
% axis equal;
% box on;
% grid on;
% hold off;


% figure()
% errorEllipse(simResult, 0.5)
% 
% % 统计距离向和方位向MAE 
%% 
% 

function [x_t, y_t, v_e, v_n] = airplanePVTrans(azimuth, speed, Range, altitude)
% 计算载机在ENU坐标系下的位置和速度
% 输入参数：载机方位角（度），载机坐标系下的名义速度，斜距，飞行高度
% 输出参数：载机在ENU坐标系下的位置和速度

R = sqrt(Range^2-altitude^2); % 地距

% 位置转换
x_t = sin(azimuth/180*pi)*R;
y_t = cos(azimuth/180*pi)*R;

% 速度转换
v_e = sin((azimuth-90)/180*pi)*speed;
v_n = cos((azimuth-90)/180*pi)*speed;

end

function [latT,lonT,hpT] = RDEwithL_M(HInit, VENU,AirplanePosition,initLoc,h0,R,sv)
    lonG = AirplanePosition(1);
    latG = AirplanePosition(2);
    % 将速度从ENU坐标转换为ecef坐标；
    ve = VENU(1);
    vn = VENU(2);
    vu = VENU(3);
    [vx,vy,vz]=enu2ecefv(ve,vn,vu,latG,lonG);
    % 定义地球椭球
    wgs84 = wgs84Ellipsoid('meter');  % 定义参考椭球 WGS84
    latInit =  initLoc(1);
    lonInit =  initLoc(2);
    ht = HInit;
    % 椭球参数
    Ra = 6378137.0;
    Rb = 6356752.3142;
    vN = sqrt(vx^2+vy^2+vz^2);% 速度归一化
    
    %     vN = 1;
    [xt0,yt0,zt0] = geodetic2ecef(wgs84,latInit,lonInit,HInit);  % 大地坐标转ecef坐标系下目标初始值
    [gx,gy,gz] = geodetic2ecef(wgs84,latG,lonG,h0);              % 载机ecef位置
    rN = sqrt((xt0-gx)^2+(yt0-gy)^2+(zt0-gz)^2); % 距离归一化
    % 使用LM算法迭代解算方程数值解，三维场景, 在ecef坐标系下；
    f = @(x)[(x(1)^2+x(2)^2+x(3)^2-R^2),
        (vx*x(1)+vy*x(2)+vz*x(3)+sv),
        ((gx+x(1))^2+(gy+x(2))^2)/(Ra+ht)^2+(gz+x(3))^2/(Rb)^2-1];
    % x3d = fsolve(f,[xt0-gx,yt0-gy,zt0-gz],optimset('Display','iter','Algorithm','levenberg-marquardt')); % 解算得到
    x3d = fsolve(f,[xt0-gx,yt0-gy,zt0-gz],optimset('Algorithm','levenberg-marquardt')); % 解算得
    
    xt = gx + x3d(1);
    yt = gy + x3d(2);
    zt = gz + x3d(3);
    [latT,lonT,hpT] = ecef2geodetic(wgs84,xt,yt,zt);
    f(x3d); % 验证数值方法解算误差
end


function errorEllipse(datamatrix,p)
    % 绘制误差椭圆 
    % print 2-demension confidence ellipse
    % In:n×2 matrix, confidence probability p
    
    data = datamatrix;
    covariance = cov(data);
    [eigenvec,eigenval] = eig(covariance);
    
    [sortEigenval,index] = sort(diag(eigenval),'descend');
    sortEigenvec = eigenvec(:,index);
    
    largestEigenval = sortEigenval(1);
    smallestEigenval = sortEigenval(end); %find the minimum eigenvalue
    largestEigenvec = sortEigenvec(:,1); %find the maximum eigenvector
    
    angle = atan2(largestEigenvec(2), largestEigenvec(1)); %calculate the angle between x-axis and the maximum eigenvector, [-pi,pi]
    
    if(angle < 0) 
        angle = angle + 2*pi;
    end
    
    avg = mean(data); %calculate the mean of two columns of data
    
    %configure the parameters of the confidence ellipse
    chisquareVal = sqrt(chi2inv(p,2)); %chi-square value
    thetaGrid = linspace(0,2*pi); 
    phi = angle; %rotation angle
    X0=avg(1);
    Y0=avg(2); 
    a=chisquareVal*sqrt(largestEigenval); %the wheelbase length
    b=chisquareVal*sqrt(smallestEigenval);
    
    ellipseXR = a*cos( thetaGrid ); %onto rectangular axis
    ellipseYR = b*sin( thetaGrid );
    
    R = [ cos(phi) sin(phi); -sin(phi) cos(phi) ]; %rotation matrix
    
    rEllipse = [ellipseXR;ellipseYR]' * R; %rotation
    
    plot(data(:,1), data(:,2), '.', rEllipse(:,1) + X0,rEllipse(:,2) + Y0,'-','LineWidth',2) %print
    % axis square
    axis equal
end


% % 载机2
% a2.h_a = 15000; % 飞行高度 m
% a2.h_t = 0; % 目标高程 m
% a2.R = 100000; % 斜距 slant m
% a2.f_dc = 0; % 多普勒中心频率 Hz
% a2.lambda = 0.21; % 波长 m
% a2.target = [0 0]; % 目标位置
% a2.speed = 250; % 速度
% a2.azimuth = 20; % 方位角
% [a2.x_t, a2.y_t, a2.v_e, a2.v_n] = airplanePVTrans(a2.azimuth, a2.speed, a2.R, a2.h_a)
% 
% a2.x_t = normrnd(a2.x_t,5,[NSim 1]); % 飞机东向位置
% a2.y_t = normrnd(a2.y_t,5,[NSim 1]); % 飞机北向位置
% a2.h_a = normrnd(a2.h_a,5,[NSim 1]); % 飞行高度 m
% a2.h_t = normrnd(a2.h_t,5,[NSim 1]); % 目标高程 m
% a2.v_e = normrnd(a2.v_e,0.1,[NSim 1]); % m/s
% a2.v_n = normrnd(a2.v_n,0.1,[NSim 1]); % m/s
% a2.v_u = normrnd(0, 0.1,[NSim 1]);     % m/s
% a2.R = normrnd(a2.R,10,[NSim 1]); % 斜距 slant m
% a2.f_dc = normrnd(0,1,[NSim 1]); % 多普勒中心频率 Hz
% 
% % simResult = zeros([NSim 2]);
% % for i=1:10000
% % h = a2.h_a(i,1) - a2.h_t(i,1); % 相对高程差
% % sv = -a2.f_dc(i,1)*a2.lambda*a2.R(i,1)/2;%
% % f = @(x)[
% %     ((a2.x_t(i,1)-x(1))^2+(a2.y_t(i,1)-x(2))^2+h^2-a2.R(i,1)^2),
% %     (a2.v_e(i,1)*(a2.x_t(i,1)-x(1))+a2.v_n(i,1)*(a2.y_t(i,1)-x(2))+a2.v_u(i,1)*h+sv)];
% % x2d = fsolve(f,[1000, -1000],optimset('Algorithm','levenberg-marquardt')); % 解算得
% % simResult(i,:) = x2d(1,:);
% % k =1;
% % end
% % resultMu = mean(simResult,1);
% % resultdelta = std(simResult,1);
% % scatter(simResult(:,1),simResult(:,2),'.');
% % axis equal
% % errorEllipse(simResult, 0.95)
% 
% 
% % 多视角
% simResult = zeros([NSim 2]);
% for i=1:10000
% 
% a1.h = a1.h_a(i,1) - a1.h_t(i,1); % 相对高程差
% a1.sv = -a1.f_dc(i,1)*a1.lambda*a1.R(i,1)/2;%
% a2.h = a2.h_a(i,1) - a2.h_t(i,1); % 相对高程差
% a2.sv = -a2.f_dc(i,1)*a2.lambda*a2.R(i,1)/2;%
% f = @(x)[
%     ((a1.x_t(i,1)-x(1))^2+(a1.y_t(i,1)-x(2))^2+a1.h^2-a1.R(i,1)^2),
%     (a1.v_e(i,1)*(a1.x_t(i,1)-x(1))+a1.v_n(i,1)*(a1.y_t(i,1)-x(2))+a1.v_u(i,1)*a1.h+a1.sv)*0.1,
%     ((a2.x_t(i,1)-x(1))^2+(a2.y_t(i,1)-x(2))^2+a2.h^2-a2.R(i,1)^2),
%     (a2.v_e(i,1)*(a2.x_t(i,1)-x(1))+a2.v_n(i,1)*(a2.y_t(i,1)-x(2))+a2.v_u(i,1)*a2.h+a2.sv)*0.1];
% x2d = fsolve(f,[1000, -1000],optimset('Algorithm','levenberg-marquardt')); % 解算得
% simResult(i,:) = x2d(1,:);
% k =1;
% end
% PositionMu2 = mean(simResult,1);
% Positiondelta2 = std(simResult,1);
% scatter(simResult(:,1),simResult(:,2),'.');
% axis equal
% errorEllipse(simResult, 0.95)
% 
% % 载机3
% a3.h_a = 15000; % 飞行高度 m
% a3.h_t = 0; % 目标高程 m
% a3.R = 100000; % 斜距 slant m
% a3.f_dc = 0; % 多普勒中心频率 Hz
% a3.lambda = 0.21; % 波长 m
% a3.target = [0 0]; % 目标位置
% a3.speed = 250; % 速度
% a3.azimuth = 40; % 方位角
% [a3.x_t, a3.y_t, a3.v_e, a3.v_n] = airplanePVTrans(a3.azimuth, a3.speed, a3.R, a3.h_a)
% 
% a3.x_t = normrnd(a3.x_t,5,[NSim 1]); % 飞机东向位置
% a3.y_t = normrnd(a3.y_t,5,[NSim 1]); % 飞机北向位置
% a3.h_a = normrnd(a3.h_a,5,[NSim 1]); % 飞行高度 m
% a3.h_t = normrnd(a3.h_t,5,[NSim 1]); % 目标高程 m
% a3.v_e = normrnd(a3.v_e,0.1,[NSim 1]); % m/s
% a3.v_n = normrnd(a3.v_n,0.1,[NSim 1]); % m/s
% a3.v_u = normrnd(0, 0.1,[NSim 1]);     % m/s
% a3.R = normrnd(a3.R,10,[NSim 1]); % 斜距 slant m
% a3.f_dc = normrnd(0,1,[NSim 1]); % 多普勒中心频率 Hz
% 
% 
% % 多视角
% simResult = zeros([NSim 2]);
% for i=1:10000
%     k = 1;
% a1.h = a1.h_a(i,1) - a1.h_t(i,1); % 相对高程差
% a1.sv = -a1.f_dc(i,1)*a1.lambda*a1.R(i,1)/2;%
% a2.h = a2.h_a(i,1) - a2.h_t(i,1); % 相对高程差
% a2.sv = -a2.f_dc(i,1)*a2.lambda*a2.R(i,1)/2;%
% a3.h = a3.h_a(i,1) - a3.h_t(i,1); % 相对高程差
% a3.sv = -a3.f_dc(i,1)*a3.lambda*a3.R(i,1)/2;%
% 
% f = @(x)[
%     ((a1.x_t(i,1)-x(1))^2+(a1.y_t(i,1)-x(2))^2+a1.h^2-a1.R(i,1)^2),
%     (a1.v_e(i,1)*(a1.x_t(i,1)-x(1))+a1.v_n(i,1)*(a1.y_t(i,1)-x(2))+a1.v_u(i,1)*a1.h+a1.sv)*0.1,
%     ((a2.x_t(i,1)-x(1))^2+(a2.y_t(i,1)-x(2))^2+a2.h^2-a2.R(i,1)^2),
%     (a2.v_e(i,1)*(a2.x_t(i,1)-x(1))+a2.v_n(i,1)*(a2.y_t(i,1)-x(2))+a2.v_u(i,1)*a2.h+a2.sv)*0.1,
%     ((a3.x_t(i,1)-x(1))^2+(a3.y_t(i,1)-x(2))^2+a3.h^2-a3.R(i,1)^2),
%     (a3.v_e(i,1)*(a3.x_t(i,1)-x(1))+a3.v_n(i,1)*(a3.y_t(i,1)-x(2))+a3.v_u(i,1)*a3.h+a3.sv)*0.1];
% x2d = fsolve(f,[1000, -1000],optimset('Algorithm','levenberg-marquardt')); % 解算得
% simResult(i,:) = x2d(1,:);
% k =1;
% end
% positionMu3 = mean(simResult,1);
% positiondelta3 = std(simResult,1);
% scatter(simResult(:,1),simResult(:,2),'.');
% axis equal
% errorEllipse(simResult, 0.95)