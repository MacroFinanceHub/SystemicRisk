% [INPUT]
% ds = A structure representing the dataset.

function analyze_dataset(varargin)

    persistent ip;

    if (isempty(ip))
        ip = inputParser();
        ip.addRequired('ds',@(x)validateattributes(x,{'struct'},{'nonempty'}));
    end

    ip.parse(varargin{:});

    ipr = ip.Results;
    ds = validate_dataset(ipr.ds);

    nargoutchk(0,0);

    analyze_dataset_internal(ds);

end

function analyze_dataset_internal(ds)

    safe_plot(@(id)plot_index(ds,id));
    safe_plot(@(id)plot_boxes('Returns',ds.Returns,ds.FirmNames,id));
    
    if (~isempty(ds.Volumes))
        safe_plot(@(id)plot_boxes('Volumes',ds.Volumes,ds.FirmNames,id));
    end
	
    if (~isempty(ds.Capitalizations))
        safe_plot(@(id)plot_boxes('Capitalizations',ds.Capitalizations,ds.FirmNames,id));
    end
    
    if (~isempty(ds.CDS))
        safe_plot(@(id)plot_risk_free_rate(ds,id));
        safe_plot(@(id)plot_boxes('CDS Spreads',ds.CDS,ds.FirmNames,id));
    end
    
    if (~isempty(ds.Assets) && ~isempty(ds.Equity))
        safe_plot(@(id)plot_boxes('Assets',ds.Assets,ds.FirmNames,id));
        safe_plot(@(id)plot_boxes('Equity',ds.Equity,ds.FirmNames,id));
        safe_plot(@(id)plot_boxes('Liabilities',ds.Liabilities,ds.FirmNames,id));
    end

end

function plot_boxes(name,x,firm_names,id)

    n = numel(firm_names);

    f = figure('Name',['Dataset > ' name],'Units','normalized','Position',[100 100 0.85 0.85],'Tag',id);    

    boxplot(x,'Notch','on','Symbol','k.');
    set(findobj(f,'type','line','Tag','Median'),'Color','g');
    set(findobj(f,'-regexp','Tag','\w*Whisker'),'LineStyle','-');
    delete(findobj(f,'-regexp','Tag','\w*Outlier'));
    
    lower_av = findobj(f,'-regexp','Tag','Lower Adjacent Value');
    lower_av = cell2mat(get(lower_av,'YData'));
    y_low = min(lower_av(:));
    y_low = y_low - abs(y_low / 10);

    upper_av = findobj(f,'-regexp','Tag','Upper Adjacent Value');
    upper_av = cell2mat(get(upper_av,'YData'));
    y_high = max(upper_av(:));
    y_high = y_high + abs(y_high / 10);
    
    ax = gca();
    set(ax,'TickLength',[0 0]);
    set(ax,'XTick',1:n,'XTickLabels',firm_names,'XTickLabelRotation',45);
    set(ax,'YLim',[y_low y_high]);

    figure_title(name);

    pause(0.01);
    frame = get(f,'JavaFrame');
    set(frame,'Maximized',true);

end

function plot_index(data,id)

    index = data.Index;

    index_obs = numel(index);
    index_max = max(index);
    index_min = min(index);
    
    index_avg = mean(index);
    index_med = median(index);
    index_std = std(index);
    index_ske = skewness(index,0);
    index_kur = kurtosis(index,0);

    f = figure('Name','Dataset > Index','Units','normalized','Position',[100 100 0.85 0.85],'Tag',id);

    sub_1 = subplot(2,1,1);
    plot(sub_1,data.DatesNum,data.Index);
    set(sub_1,'XLim',[data.DatesNum(1) data.DatesNum(end)],'XTickLabelRotation',45);
    set(sub_1,'YLim',[(index_min - 0.01) (index_max + 0.01)]);
    set(sub_1,'XGrid','on','YGrid','on');
    t1 = title(sub_1,'Log Returns');
    set(t1,'Units','normalized');
    t1_position = get(t1,'Position');
    set(t1,'Position',[0.4783 t1_position(2) t1_position(3)]);

    if (data.MonthlyTicks)
        date_ticks(sub_1,'x','mm/yyyy','KeepLimits','KeepTicks');
    else
        date_ticks(sub_1,'x','yyyy','KeepLimits');
    end
    
    sub_2 = subplot(2,1,2);
    hist = histogram(sub_2,data.Index,50,'FaceColor',[0.749 0.862 0.933],'Normalization','pdf');
    edges = get(hist,'BinEdges');
    edges_max = max(edges);
    edges_min = min(edges);
    [values,points] = ksdensity(data.Index);
    hold on;
        plot(sub_2,points,values,'-b','LineWidth',1.5);
    hold off;
    set(sub_2,'XLim',[(edges_min - (edges_min * 0.1)) (edges_max - (edges_max * 0.1))]);
    t2 = title(sub_2,'P&L Distribution');
    set(t2,'Units','normalized');
    t2_position = get(t2,'Position');
    set(t2,'Position',[0.4783 t2_position(2) t2_position(3)]);

    t = figure_title(['Index (' data.IndexName ')']);
    t_position = get(t,'Position');
    set(t,'Position',[t_position(1) -0.0157 t_position(3)]);
    
    annotation_strings = {sprintf('Observations: %d',index_obs) sprintf('Mean: %.4f',index_avg) sprintf('Median: %.4f',index_med) sprintf('Standard Deviation: %.4f',index_std) sprintf('Skewness: %.4f',index_ske) sprintf('Kurtosis: %.4f',index_kur)};
    annotation('TextBox',(get(sub_2,'Position') + [0.01 -0.025 0 0]),'String',annotation_strings,'EdgeColor','none','FitBoxToText','on','FontSize',8);
    
    pause(0.01);
    frame = get(f,'JavaFrame');
    set(frame,'Maximized',true);

end

function plot_risk_free_rate(data,id)

    rfr = data.RiskFreeRate;
    y_limits_rfr = plot_limits(rfr,0.1);
    
    rfr_pc = [0; (((rfr(2:end) - rfr(1:end-1)) ./ rfr(1:end-1)) .* 100)];
    y_limits_rfr_pc = plot_limits(rfr_pc,0.1);

    f = figure('Name','Dataset > Risk-Free Rate','Units','normalized','Position',[100 100 0.85 0.85],'Tag',id);

    sub_1 = subplot(2,1,1);
    plot(sub_1,data.DatesNum,smooth_data(rfr));
    set(sub_1,'XLim',[data.DatesNum(1) data.DatesNum(end)],'XTickLabelRotation',45);
    set(sub_1,'YLim',y_limits_rfr);
    set(sub_1,'XGrid','on','YGrid','on');
    t1 = title(sub_1,'Trend');
    set(t1,'Units','normalized');
    t1_position = get(t1,'Position');
    set(t1,'Position',[0.4783 t1_position(2) t1_position(3)]);

    sub_2 = subplot(2,1,2);
    plot(sub_2,data.DatesNum,rfr_pc);
    set(sub_2,'XLim',[data.DatesNum(1) data.DatesNum(end)],'XTickLabelRotation',45);
    set(sub_2,'YLim',y_limits_rfr_pc);
    set(sub_2,'YTickLabels',arrayfun(@(x)sprintf('%.f%%',x),get(sub_2,'YTick'),'UniformOutput',false));
    t2 = title(sub_2,'Percent Change');
    set(t2,'Units','normalized');
    t2_position = get(t2,'Position');
    set(t2,'Position',[0.4783 t2_position(2) t2_position(3)]);

    if (data.MonthlyTicks)
        date_ticks([sub_1 sub_2],'x','mm/yyyy','KeepLimits','KeepTicks');
    else
        date_ticks([sub_1 sub_2],'x','yyyy','KeepLimits');
    end
    
    t = figure_title('Risk-Free Rate');
    t_position = get(t,'Position');
    set(t,'Position',[t_position(1) -0.0157 t_position(3)]);

    pause(0.01);
    frame = get(f,'JavaFrame');
    set(frame,'Maximized',true);

end
