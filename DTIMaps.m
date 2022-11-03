function [map_dicom] = DTIMaps(tensor_dicom,contours,varargin)
% in:
% tensor_dicom - struct containing tensors from diffusion images
% contours - struct containting contours
% viewHA - set flag to view helix angle filter outputs
% 
% out:
% map_dicom - struct containing diffusion maps
% 
% description:
% create maps for MD, FA, HA, TRA, and E2A

map_dicom = [];

cardiacphases = fieldnames(tensor_dicom);

viewHA = 0;
if ~isempty(varargin)
    viewHA = varargin{1};
end
    

for i=1:length(cardiacphases)
    slicelocation = fieldnames(tensor_dicom.(cardiacphases{i}));
    for j=1:length(slicelocation)
        tensor_struct = tensor_dicom.(cardiacphases{i}).(slicelocation{j});
        
        if isempty(tensor_struct)
            s1 = struct('MD',{},'FA',{},'AD',{},'RD',{},'Trace',{},'HA',{},'HA_filt',{},'E2A',{},'TRA',{},'SA',{},'radians',{});
            map_dicom.(cardiacphases{i}).(slicelocation{j}) = s1;
            continue
        end
        
        h = waitbar(0,'Generating DTI maps...');
        
%         TMPtensor = tensor_struct.tensor;
        TMPeigVector = tensor_struct.eigVector;
        TMPeigValue = tensor_struct.eigValue;

        epi = contours.epi{j};
        endo = contours.endo{j};
        roisize = size(epi);
%         roisize2 = size(endo);
        M_myo = contours.myoMask{j};
        M_depth = contours.depthMask{j};

        lowb = fieldnames(TMPeigValue);
        n = length(lowb);
    
        count = 0;
%         wrong = zeros(n*(n+1)/2,1);
    
        for lb=1:n
            highb = fieldnames(TMPeigValue.(lowb{lb}));
            for hb=1:length(highb)
                count = count+1;
            
                eigValue = TMPeigValue.(lowb{lb}).(highb{hb});
                eigVector = TMPeigVector.(lowb{lb}).(highb{hb});
                imsize = size(eigValue);
                [Xq,Yq] = meshgrid(1:imsize(2),1:imsize(1));
            
                ev1 = squeeze(eigVector(:,:,:,1)); %primary eigenvector - fibre vector
                ev2 = squeeze(eigVector(:,:,:,2)); %secondary eigenvector - sheet vector
                ev3 = squeeze(eigVector(:,:,:,3)); %tertiary eigenvector - sheet normal vector

                epiVect = zeros(roisize);
                endoVect = epiVect;
%                 endoVect = zeros(roisize2);
            
                %% caluclate contour circumferential vectors
                epiVect(end,:) = epi(1,:) - epi(end,:);
                endoVect(end,:) = endo(1,:) - endo(end,:);
                for k=1:roisize(1)-1
                    epiVect(k,:) = epi(k+1,:) - epi(k,:);
%                 end
%                 for k=1:roisize2(1)-1
                    endoVect(k,:) = endo(k+1,:) - endo(k,:);
                end
            
                posROI = cat(1,epi,endo);
                vecROI = cat(1,epiVect,endoVect);
            
                %% Contour circ vects are used to calculate local circ vect for each pixel
                Fx = scatteredInterpolant(posROI(:,1),posROI(:,2),vecROI(:,1));%,'linear','none');
                Fy = scatteredInterpolant(posROI(:,1),posROI(:,2),vecROI(:,2));%,'linear','none');
                Vx = Fx(Xq,Yq);
                Vy = Fy(Xq,Yq);
                
                % Longitudinal Vector
                LongVect = [0 0 1];
                LongVect = LongVect/norm(LongVect);

                TMPmd = zeros(imsize(1:2));
                TMPfa = zeros(imsize(1:2));
                TMPad = zeros(imsize(1:2));
                TMPrd = zeros(imsize(1:2));
                TMPtrace = zeros(imsize(1:2));
                TMPha = zeros(imsize(1:2));
                TMPtra = zeros(imsize(1:2));
                TMPe2a = zeros(imsize(1:2));
                TMPhaRad = zeros(imsize(1:2));
                TMPtraRad = zeros(imsize(1:2));
                TMPe2aRad = zeros(imsize(1:2));
                TMPsa = zeros(imsize(1:2));
                TMPsaRad = zeros(imsize(1:2));
            
                for row=1:imsize(1)
                    for col=1:imsize(2)
%                         if M_myo(row,col)
                        %% calculate rotational invariants
                        eigValue_px = squeeze(eigValue(row,col,:));
                        I1 = sum(eigValue_px); % trace
%                         I3 = det(diag(eigValue_px)); % determinant
                        I4 = sum(eigValue_px.^2); % D:D
                        I2 = (I1^2-I4)/2; % scalar invariant 2
                        
                        if abs(I2-I4)<1E-15
                            I2 = I4;
                        end
                        if I2/I4>1
                            disp(abs(I2-I4));
                            I2 = I4;
                        end
                            
                        %% calculate MD and FA
                        TMPmd(row,col) = I1/3; % mean diffusivity
                        TMPfa(row,col) = sqrt(1-I2/I4); % fractional anisotropy
                        TMPtrace(row,col) = I1; % trace map
                        
                        %% calculate AD and RD
                        TMPad(row,col) = eigValue_px(1); % axial diffusivity
                        TMPrd(row,col) = (eigValue_px(2) + eigValue_px(3))/2; % radial diffusivity

                        %% calculate HA and E2A
                        % Fibre and Sheet Vector
                        E1Vect = squeeze(ev1(row,col,:))'; %FibreVect
                        E2Vect = squeeze(ev2(row,col,:))'; %SheetVect
                        E3Vect = squeeze(ev3(row,col,:))'; %SheetNorm

                        % Circumferential Vector
                        CircVect = [Vx(row,col) Vy(row,col) 0];
                        CircVect = CircVect/norm(CircVect);
                        
                        % Radial Vector
                        RadVect = cross(CircVect,LongVect);
                        RadVect = RadVect/norm(RadVect);

                        % Project Fibre vector radially onto local wall
                        % tangent plane - https://doi.org/10.1186/s12968-014-0087-8
                        E1RadProj = E1Vect - RadVect*dot(RadVect,E1Vect); % remove radial component of fibre vector
                        E1RadProj = E1RadProj/norm(E1RadProj);
                        
                        % Projection of the Fibre Vector onto the short axis plane
                        E1LongProj = E1Vect  - LongVect*dot(E1Vect,LongVect); % remove longitudinal component of fibre vector
                        E1LongProj = E1LongProj/norm(E1LongProj);
                        % Midfibre vector - https://doi.org/10.1186/s12968-014-0087-8
%                         MidFibreVect2 = cross(E1Proj,RadVect); %equivalent
                        MidFibreVect = cross(E1Vect,RadVect); %cross-myocyte
                        MidFibreVect = MidFibreVect/norm(MidFibreVect);
                        
                        % Projection of the Sheet Vector onto the mid-fibre plane
                        E2Proj = E2Vect - E1RadProj*dot(E1RadProj,E2Vect); % remove fibre projection component of sheet vector
                        E2Proj = E2Proj/norm(E2Proj);

                        % Projection of the Sheet Normal Vector onto the mid-fibre plane
                        E3Proj = E3Vect - CircVect*dot(E3Vect,CircVect);
                        E3Proj = E3Proj/norm(E3Proj);
    
                        %Helix angle - if E1(circ)/E1(long)>=0 -> angle<=0
                        haRad2 = asin(dot(E1RadProj,LongVect)); %other ha method (equiv with correction)
%                         haDeg2 = asind(dot(E1RadProj,LongVect)); %
                        haRad = -atan(dot(E1RadProj,LongVect)/dot(E1RadProj,CircVect)); %https://doi.org/10.1186/s12968-014-0087-8
                        haDeg = -atand(dot(E1RadProj,LongVect)/dot(E1RadProj,CircVect)); %degrees
                        %Transverse angle - if E1(rad)/E1(circ)>=0 -> angle>=0
                        traRad2 = asin(dot(E1LongProj,RadVect)); %other tra method (equiv with correction)
%                         traDeg2 = asind(dot(E1LongProj,RadVect)); %
                        traRad = atan(dot(E1LongProj,RadVect)/dot(E1LongProj,CircVect)); %https://doi.org/10.1109/tmi.2012.2192743
                        traDeg = atand(dot(E1LongProj,RadVect)/dot(E1LongProj,CircVect)); %degrees
                        %Second eigenvector angle
%                         e2aRad2 = -atan(dot(E2Vect,RadVect)/dot(E2Vect,MidFibreVect)); %other e2a method (equiv of other method)
%                         e2aDeg2 = -atand(dot(E2Vect,RadVect)/dot(E2Vect,MidFibreVect)); %degrees
                        e2aRad = -atan(dot(E2Proj,RadVect)/dot(E2Proj,MidFibreVect)); %https://doi.org/10.1186/s12968-014-0087-8
                        e2aDeg = -atand(dot(E2Proj,RadVect)/dot(E2Proj,MidFibreVect)); %degrees
                        %Sheet angle - if E3(rad)/E3(long)>=0 -> angle>=0
                        saRad = atan(dot(E3Proj,RadVect)/dot(E3Proj,LongVect));
                        saDeg = atand(dot(E3Proj,RadVect)/dot(E3Proj,LongVect));
                        
                       
                        %% only necessary if using asin(..)
                        if dot(CircVect,E1Vect)>0
%                             haDeg2 = -haDeg2;
                            haRad2 = -haRad2;
                        end
                        if dot(CircVect,E1LongProj)<0
%                             traDeg2 = -traDeg2;
                            traRad2 = -traRad2;
                        end
%                         if (abs(haRad-haRad2)>1e-6)
%                             'here'
%                         end
%                         if (abs(traRad-traRad2)>1e-6)
%                             'here1'
%                         end
%                         if (abs(e2aRad-e2aRad2)>1e-6)
%                             'here2'
%                         end
                        
                        TMPha(row,col) = haDeg;
                        TMPe2a(row,col) = e2aDeg;
                        TMPtra(row,col) = traDeg;
                        TMPhaRad(row,col) = haRad;
                        TMPe2aRad(row,col) = e2aRad;
                        TMPtraRad(row,col) = traRad;
                        
                        TMPsa(row,col) = saDeg;
                        TMPsaRad(row,col) = saRad;
%                         end %if M_myo(row,col)
                    end
                end
            
                TMPhafilt = filterHA(TMPha,M_myo,M_depth,viewHA);
                TMPhafiltRad = filterHA(TMPhaRad,M_myo,M_depth,viewHA,1);
            
                MD.(lowb{lb}).(highb{hb}) = TMPmd;
                FA.(lowb{lb}).(highb{hb}) = TMPfa;
                AD.(lowb{lb}).(highb{hb}) = TMPad;
                RD.(lowb{lb}).(highb{hb}) = TMPrd;
                Trace.(lowb{lb}).(highb{hb}) = TMPtrace;
                HA.(lowb{lb}).(highb{hb}) = TMPha;
                HA_filt.(lowb{lb}).(highb{hb}) = TMPhafilt;
                E2A.(lowb{lb}).(highb{hb}) = TMPe2a;
                TRA.(lowb{lb}).(highb{hb}) = TMPtra;
                SA.(lowb{lb}).(highb{hb}) = TMPsa;
                
                HArad.(lowb{lb}).(highb{hb}) = TMPhaRad;
                HA_filtrad.(lowb{lb}).(highb{hb}) = TMPhafiltRad;
                E2Arad.(lowb{lb}).(highb{hb}) = TMPe2aRad;
                TRArad.(lowb{lb}).(highb{hb}) = TMPtraRad;
                SArad.(lowb{lb}).(highb{hb}) = TMPsaRad;

                waitbar(count/(n*(n+1)/2),h);
            end
        end

        map_dicom.(cardiacphases{i}).(slicelocation{j}).MD = MD;
        map_dicom.(cardiacphases{i}).(slicelocation{j}).FA = FA;
        map_dicom.(cardiacphases{i}).(slicelocation{j}).AD = AD;
        map_dicom.(cardiacphases{i}).(slicelocation{j}).RD = RD;
        map_dicom.(cardiacphases{i}).(slicelocation{j}).Trace = Trace;
        map_dicom.(cardiacphases{i}).(slicelocation{j}).HA = HA;
        map_dicom.(cardiacphases{i}).(slicelocation{j}).HA_filt = HA_filt;
        map_dicom.(cardiacphases{i}).(slicelocation{j}).E2A = E2A;
        map_dicom.(cardiacphases{i}).(slicelocation{j}).TRA = TRA;
        map_dicom.(cardiacphases{i}).(slicelocation{j}).SA = SA;
        
        map_dicom.(cardiacphases{i}).(slicelocation{j}).radians.HA = HArad;
        map_dicom.(cardiacphases{i}).(slicelocation{j}).radians.HA_filt = HA_filtrad;
        map_dicom.(cardiacphases{i}).(slicelocation{j}).radians.E2A = E2Arad;
        map_dicom.(cardiacphases{i}).(slicelocation{j}).radians.TRA = TRArad;
        map_dicom.(cardiacphases{i}).(slicelocation{j}).radians.SA = SArad;
        
        clearvars MD FA AD RD Trace HA HA_filt E2A TRA HArad HA_filtrad E2Arad TRArad SA SArad

        close(h);
    end
end

end

function HA_filt = filterHA(HA,Mask,Depth,varargin)
% in:
% HA - helix angle map
% Mask - LV myocardium mask
% Depth - LV depth mask
% {view_flag} - display intermediate figures during filtering
% {radians} - figures should be displayed in radians instead of degrees
% 
% out:
% HA_filt - filtered helix angle map
% 
% description:
% filter HA for outliers. Based on HA_Filter_KM.m by Kevin Moulin

view_flag = 0;
radians = 0;
if nargin>3
    view_flag = varargin{1};
end
if nargin>4
    radians = varargin{2};
end

HA_filt = HA;
HA_myo = HA(Mask);
Depth_myo = Depth(Mask);

[row,col] = find(Mask);

%% remove NaNs from lists
Depth_myo(isnan(HA_myo)) = nan;
HA_myo(isnan(Depth_myo)) = nan;
Depth_myo(isnan(Depth_myo)) = [];
HA_myo(isnan(HA_myo)) = [];

%% Display
if view_flag
    figure
    scatter(Depth_myo,HA_myo,[],'r','filled');
    if radians
        axis([0 1 -0.6*pi 0.6*pi])
        set(gca,'YTick',[-pi/2 -pi/4 0 pi/4 pi/2]);
    else
        axis([0 1 -1.2*100 1.2*100])
        set(gca,'YTick',[-90 -45 0 45 90]);
    end
    set(gca,'XTick',[0 0.25 0.5 0.75 1]);
    set(gca,'XTickLabel',{'Endo','','Mid','','Epi'});
    
    xlabel('')
    ylabel('HA(°)')
    set(gca, 'box', 'off') % remove top x-axis and right y-axis
    set(gcf, 'color', [1 1 1]);
    set(gca, 'color', [1 1 1]);
    ax = gca;
    ax.XColor = 'black';
    ax.YColor = 'black';
    ax.FontSize=15;
    ax.FontWeight='bold';

    legend('off');
    grid off
end

%% HA<-->depth relationship is linear, look for outliers from linear fit
f = fittype('a*x+b');
fitobject = fit(Depth_myo,HA_myo,f,'StartPoint',[1 1]);
fdata = feval(fitobject,Depth_myo);
I = abs(fdata - HA_myo) > 1.5*std(HA_myo);
outliers = excludedata(Depth_myo,HA_myo,'indices',I);

%% Display
if view_flag
    figure
    scatter(Depth_myo(~outliers),HA_myo(~outliers),[],'r','filled');
    hold on
    scatter(Depth_myo(outliers),HA_myo(outliers),[],'m','filled');
    hold off
    plot(Depth_myo,fdata,'-k','LineWidth',4)
    plot((0:0.01:1),fitobject(0:0.01:1)+1.5*std(HA_myo),':k','LineWidth',4)
    plot((0:0.01:1),fitobject(0:0.01:1)-1.5*std(HA_myo),':k','LineWidth',4)
    if radians
        axis([0 1 -0.6*pi 0.6*pi])
        set(gca,'YTick',[-pi/2 -pi/4 0 pi/4 pi/2]);
        ylabel('HA(rad)')
    else
        axis([0 1 -1.2*100 1.2*100])
        set(gca,'YTick',[-90 -45 0 45 90]);
        ylabel('HA(°)')
    end
    set(gca,'XTick',[0 0.25 0.5 0.75 1]);
    set(gca,'XTickLabel',{'Endo','','Mid','','Epi'});
    
    xlabel('')
    set(gca, 'box', 'off') % remove top x-axis and right y-axis
    set(gcf, 'color', [1 1 1]);
    set(gca, 'color', [1 1 1]);
    ax = gca;
    ax.XColor = 'black';
    ax.YColor = 'black';
    ax.FontSize=15;
    ax.FontWeight='bold';


    legend('off');
    grid off
    hold off
end

%% If outliers are negative&endo or positive&epi, flip the sign
HA_outliers = HA_myo(outliers);
Depth_outliers = Depth_myo(outliers);
NegEndo = Depth_outliers<0.5 & HA_outliers<0;
PosEpi = Depth_outliers>0.5 & HA_outliers>0;
HA_outliers(NegEndo|PosEpi) = -HA_outliers(NegEndo|PosEpi);
HA_myo(outliers) = HA_outliers;

%% Display
if view_flag
    figure
    scatter(Depth_myo(~outliers),HA_myo(~outliers),[],'r','filled');
    hold on
    scatter(Depth_myo(outliers),HA_myo(outliers),[],'m','filled');
    hold off
    if radians
        axis([0 1 -0.6*pi 0.6*pi])
        set(gca,'YTick',[-pi/2 -pi/4 0 pi/4 pi/2]);
        ylabel('HA(rad)')
    else
        axis([0 1 -1.2*100 1.2*100])
        set(gca,'YTick',[-90 -45 0 45 90]);
        ylabel('HA(°)')
    end
    set(gca,'XTick',[0 0.25 0.5 0.75 1]);
    set(gca,'XTickLabel',{'Endo','','Mid','','Epi'});
    
    xlabel('')
    set(gca, 'box', 'off') % remove top x-axis and right y-axis
    set(gcf, 'color', [1 1 1]);
    set(gca, 'color', [1 1 1]);
    ax = gca;
    ax.XColor = 'black';
    ax.YColor = 'black';
    ax.FontSize=15;
    ax.FontWeight='bold';

    legend('off');
    grid off
end

%%
HA_filt(sub2ind(size(HA_filt),row,col)) = HA_myo;

end