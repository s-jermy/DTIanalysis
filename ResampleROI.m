function [nfo2,contours2] = ResampleROI(nfo,contours)

nfo2 = nfo;
contours2 = contours;

P_Epi = contours2.epi;
P_Endo = contours.endo;

for i=1:length(P_Epi)
    epi = P_Epi{i};
    endo = P_Endo{i};
    
    epi2 = interparc(200,epi(:,1),epi(:,2),'pchip');
    endo2 = interparc(200,endo(:,1),endo(:,2),'pchip');
    
    P_Epi{i} = epi2;
    P_Endo{i} = endo2;
    
    nfo2{i}.contoursDefined = 1;
end

contours2.epi = P_Epi;
contours2.endo = P_Endo;

end