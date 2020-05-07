% This file is part of DAVE, a MATLAB toolbox for data evaluation.
% Copyright (C) 2018-2019 Saarland University, Author: Manuel Bastuck
% Website/Contact: www.lmt.uni-saarland.de, info@lmt.uni-saarland.de
% 
% The author thanks Tobias Baur, Tizian Schneider, and Jannis Morsch
% for their contributions.
% 
% This program is free software: you can redistribute it and/or modify
% it under the terms of the GNU Affero General Public License as published
% by the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.
% 
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU Affero General Public License for more details.
% 
% You should have received a copy of the GNU Affero General Public License
% along with this program.  If not, see <http://www.gnu.org/licenses/>. 

function [panel,updateFun] = selectedFeatures(parent,project,dataprocessingblock)
    [panel,elements] = makeGui(parent,project,dataprocessingblock);
    populateGui(elements,project,dataprocessingblock);
    updateFun = @()populateGui(elements,project,dataprocessingblock);
end

function [panel,elements] = makeGui(parent,project,dataprocessingblock)
    panel = uipanel(parent);
    layout = uiextras.VBox('Parent',panel);
    panel2 = uipanel(layout,'BorderType','none');
    hAx = axes(panel2); title('');
    box on,
    set(gca,'LooseInset',get(gca,'TightInset')) % https://undocumentedmatlab.com/blog/axes-looseinset-property
    elements.hAx = hAx;
    
    dropdown = uicontrol(layout, 'Style','popupmenu');
    dropdown.String = {''};
    elements.dropdown = dropdown;
    dropdown.Callback = @(varargin)populateGui(elements,project,dataprocessingblock);
    layout.Sizes = [-1,20];
end

function populateGui(elements,project,dataprocessingblock)
    try
        try
            elements.dropdown.String=project.currentCluster.sensors.getCaption();
            selSens=elements.dropdown.String{elements.dropdown.Value};
        catch
            selSens=elements.dropdown.String;
        end

        for i=1:length(project.currentCluster.sensors)
            sensor = project.currentCluster.sensors(1, i);
            if strcmp(sensor.caption,selSens)
                newsensor = sensor;
            end
        end

        getGroup=single(project.currentCluster.featureData.groupings);
        setGroup=getGroup(:,1);
        setGroup(~isnan(setGroup))=1;
        setGroup(isnan(setGroup))=0;
        setGroup=logical(setGroup);

        allData=newsensor.data;
        redDat=allData(setGroup,:);

        x1 = 1:1:newsensor.cluster.nCyclePoints;
        x = x1.*newsensor.cluster.samplingPeriod;

    %     plot(elements.hAx,x,redDat(1,:));
    %     xlabel(elements.hAx,'time');
    %     ylabel(elements.hAx,'data a.u.');
    %     
        minfill=min(redDat(:))-5e3;
        maxfill=max(redDat(:))+5e3;
        
        f.EdgeColor=[0.5 0.5 0.5];
        featCap=project.currentModel.fullModelData.featureCaptions;
        yfill=[minfill,minfill,maxfill,maxfill]';
        
        try
            dpbmean=newsensor.featureDefinitionSet.featureDefinitions.getByCaption('mean').dataProcessingBlock;
            iPosmean=dpbmean.parameters.getByCaption('iPos').value;

            indMean = find(contains(featCap,'mean')&contains(featCap,selSens));

            selMean=project.currentModel.fullModelData.featureSelection(indMean(1):indMean(end))';
            selR1=iPosmean(selMean,:).*newsensor.cluster.samplingPeriod;

            xfillm=[selR1(:,1),selR1(:,2),selR1(:,2),selR1(:,1)]';
        
            f=fill(elements.hAx,xfillm,yfill,[1 1 .6]);
            hold(elements.hAx,'on');
        end
        
        try
            dpbpoly=newsensor.featureDefinitionSet.featureDefinitions.getByCaption('polyfit').dataProcessingBlock;
            iPospoly=dpbpoly.parameters.getByCaption('iPos').value;

            indPoly = find(contains(featCap,'polyfit')&contains(featCap,selSens));

            selPoly=project.currentModel.fullModelData.featureSelection(indPoly(1):indPoly(end))';
            selR2=iPospoly(selPoly,:).*newsensor.cluster.samplingPeriod; 

            xfillp=[selR2(:,1),selR2(:,2),selR2(:,2),selR2(:,1)]';
   
            f=fill(elements.hAx,xfillp,yfill,[1 .6 .6]);
            %f.EdgeColor=[.5 .5 .5];
            hold(elements.hAx,'on');
        end
        
        try
            [~,row,~] = intersect(selR1(:,1),selR2(:,1));
            selR3=iPosmean(selMean,:).*newsensor.cluster.samplingPeriod;
            selR3=selR3(row,:);

            xfillmp=[selR3(:,1),selR3(:,2),selR3(:,2),selR3(:,1)]';
        
            f=fill(elements.hAx,xfillmp,yfill,[0 1 0]);
        end
        %f.EdgeColor=[.5 .5 .5];

        plot(elements.hAx,x,redDat(1,:),'color','b');
        xlabel(elements.hAx,'time');
        ylabel(elements.hAx,'data a.u.');
        ylim(elements.hAx,[minfill maxfill]);
        fprintf('\n \n Mean: yellow \n Polyfit: red \n Mean&Polyfit: green \n \n');
        hold(elements.hAx,'off');

    %     plot(elements.hAx,x,errorTr(nCompPLSR,:),'k',x,errorV(nCompPLSR,:),'r',x,errorTe(end,:),'b');
    %     xlabel('time');
    %     ylabel('data a.u.');
    %     legend(elements.hAx,'Training','Validation','Testing');
    end
end