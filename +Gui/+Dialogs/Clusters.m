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

classdef Clusters < handle
    properties
        main
        f
        hTable
        normalizeCycleDurationButton
        deleteButton
        plotButton
        applyButton
    end
    
    methods
        function obj = Clusters(main)
            obj.main = main;
            obj.f = figure('Name','Clusters','WindowStyle','modal',...
                'CloseRequestFcn',@(varargin)obj.onDialogClose);
            layout = uiextras.VBox('Parent',obj.f);
            
            obj.hTable = JavaTable(layout,'default');
            obj.refreshTable();
            
             obj.applyButton = uicontrol(layout,...
                'String','Apply',...
                'Callback',@(h,e)obj.applyButtonClicked);
            
            obj.plotButton = uicontrol(layout,...
                'String','plot tracks',...
                'Callback',@(h,e)obj.plotButtonClicked);
            
            obj.normalizeCycleDurationButton = uicontrol(layout,...
                'String','normlaize all cycle durations',...
                'Callback',@(h,e)obj.normalizeCycleDurationsButtonClicked);
            obj.deleteButton = uicontrol(layout,...
                'String','delete...',...
                'Callback',@(h,e)obj.deleteButtonClicked);
            
            layout.Sizes = [-1,30,30,30,30];
        end

        function tableDataChange(obj,rc,v)
            for i = 1:size(rc,1)
                o = obj.hTable.getRowObjectsAt(rc(i,1));
                switch rc(i,2)
                    case 1
                        c1 = obj.main.project.clusters;
                        c2 = c1.getCaption();
                        for j=1:length(c2)
                            if (c2(j))==v{i} && j ~= rc(1)
                                v{i} = 'error';
                            end
                        end
                        o.setCaption(v{i});
                    case 2
                        o.track = v{i};
                    case 3
                        o.offset = v{i};
                        iOffset = o.getAutoIndexOffset(obj.main.project.clusters);
                        o.indexOffset = iOffset;                        
                    case 4
                        o.samplingPeriod = v{i};
                end
            end
        end
        
        function normalizeCycleDurationsButtonClicked(obj)
            clusters = obj.main.project.clusters;
            for i = 1:numel(clusters)
                clusters(i).samplingPeriod = 1 / clusters(i).nCyclePoints;
            end
            obj.refreshTable();
        end
        
        function applyButtonClicked(obj)
            obj.refreshTable();
        end
        
        function plotButtonClicked(obj)
            for i=1:length(obj.main.project.clusters)
                try
                    coll(i) = obj.main.project.clusters(i, 1).track;
                catch
                    coll(i) = obj.main.project.clusters(1, i).track;
                end
            end
            tracks = unique(coll);
            X = 1:1:length(tracks);

            % get cluster for individual track
            for i=1:length(tracks)
                k = 1;
                for j=1:length(obj.main.project.clusters)
                    try
                        att = obj.main.project.clusters(j, 1);
                    catch
                        att = obj.main.project.clusters(1, j);
                    end
                    if strcmp(att.track,tracks(i))
                        clust(i,k) = att;
                        k = k+1;
                    end
                end
            end

            for i=1:size(clust,1)
                sclust = clust(i,:);
                b(1,1:4) = 0;
                % create table and sort
                for j=2:length(sclust)+1
                    b(j,1)=sclust(1, j-1).offset;
                    b(j,2)=sclust(1, j-1).samplingPeriod;
                    b(j,3)=sclust(1, j-1).nCyclePoints;
                    b(j,4)=sclust(1, j-1).nCycles;
                end
                b(any(isnan(b), 2),:) = [];
                b = sortrows(b,1);
                % create Y variable for plot
                l=1;
                Y(i,1) = 0;
                for k=1:size(b,1)
                    Y(i,l) = b(k,1)-sum(Y(i,1:(l-1)));
                    Y(i,l+1) = b(k,2)*b(k,3)*b(k,4);
                    l = l+2;
                end
            end
            Y(:,1:2) = [];
            figure;
            H = barh(X,Y,'stacked');
            yticklabels(tracks);
            setB = 1:2:size(Y,2);
            set(H(setB),'Visible','off');
            set(gcf,'Position',[20,200,1500,200]);
            if any(Y(:)<0)
                error('At least two cluster of one track are not separated.');
            end
        end
        
        function deleteButtonClicked(obj)
            c = obj.main.project.clusters;
            captions = c.getCaption();
            [sel,ok] = listdlg('ListString',captions);
            if ~ok
                return
            end
            obj.main.project.clusters(sel) = [];
            obj.refreshTable();
            obj.main.populateSensorSetTable();
        end
        
        function refreshTable(obj)
            t = obj.hTable;
            c = obj.main.project.clusters;
            data = cell(numel(c),6);
            for i = 1:numel(c)
                data{i,1} = char(c(i).getCaption());
                data{i,2} = char(c(i).track);
                data{i,3} = c(i).offset;
                data{i,4} = c(i).samplingPeriod;
                data{i,5} = c(i).nCycles;
                data{i,6} = c(i).nCyclePoints;
            end
            t.setData(data,{'caption','track','offset','sampling period','cycles','cycle points'});
            t.setColumnsEditable([true true true true false false]);
            t.setColumnClasses({'str','str','double','double','int','int'});
            t.setRowObjects(c);
            t.onDataChangedCallback = @obj.tableDataChange;
        end

        function onDialogClose(obj)
            try
                obj.main.getActiveModule().onOpen();
                obj.main.populateSensorSetTable();
            catch ME
                warning(ME.message);
            end
            delete(obj.f);
        end
    end
end