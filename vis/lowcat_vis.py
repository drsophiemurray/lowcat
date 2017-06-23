'''
Created on 2017 May 11

@author: smurray

Python Version:    2.7.2 (default, Oct  1 2012, 15:56:20)
Working directory:     ~/GitHub/lowcat/vis

Description:

Notes:

'''

CAT_FOLDER = '/Users/sophie/GitHub/lowcat/data/'
JSON_FILE = 'lowcat.json'
SAV_FILE = 'lowcat.sav' #outstr and cmelist
FLARECAST_FILE = '/Users/sophie/Dropbox/flarecast_helcats/helcats_list_flarecast_properties_30May17_3.txt'
FLARECAST_CSV = '/Users/sophie/flarecast.csv'

import numpy as np
import datetime as dt
from scipy.io.idl import readsav
import pandas as pd
# import json
# from bokeh.charts import Scatter, output_file, show
# from glue import qglue
import plotly.graph_objs as go
import plotly.plotly as py
from plotly import tools


def main():
    """Loads the LOWCAT catalogue, 
    fixes some data formats,
    then loads the glue GUI to play around with the plots"""
    # Load the .sav file
    savfile = readsav(CAT_FOLDER+SAV_FILE)

    # Fix some of the data into a format that is more suitable
    outstr = fix_data(savfile['outstr'])
    data = pd.DataFrame(outstr)

    # Now mess around with visualisation
    #try_bokeh(outstr)
    #qglue(data1=data)
    # plotly_single(xdata = data['SMART_RVALUE'], ydata = data['COR2_V'],
    #                weightdata = '16', colourdata = data['COR2_WIDTH'],
    #                filedata = 'rvaluevwidth'
    #                )

    # Calculate flare duration
    data['FL_DURATION'] = calculate_flare_duration(data['FL_STARTTIME'], data['FL_ENDTIME'])

    # Create multiplots subplots in plot.ly
    plotly_multi(x1data = np.log10(data['FL_GOES'].astype('float64')), x1title = 'log10 GOES Flux',
                 x2data = np.log10(data['FL_DURATION'].astype('float64')),  x2title = 'log10 Flare duration',
                 x3data = np.log10(data['SRS_NN'].astype('float64')), x3title = 'log10 SRS no. spots',
                 x4data = np.log10(data['SMART_TOTAREA'].astype('float64')), x4title = 'log10 Total area [m.s.h.]',
                 x5data = np.log10(data['SMART_TOTFLX'].astype('float64')), x5title = 'log10 Total flux [Mx]',
                 x6data = np.log10(data['SMART_BMEAN'].astype('float64')), x6title = 'log10 Bmean [G]',
                 x7data = np.log10(data['SMART_BIPOLESEP'].astype('float64')), x7title = 'log10 Bipole separation [Mm]',
                 x8data = data['SMART_RVALUE'], x8title = 'log10 R value [Mx]',
                 x9data = data['SMART_WLSG'], x9title = 'log10 WLsg [G/Mm]',
                 y1data = data['COR2_V'], y1title = 'CME Speed [ms<sup>-1</sup>]',
                 y1range = [0, 2000],
                 weightdata = '10',
                 colourdata = data['COR2_WIDTH'], colourdata_title = 'CME width [<sup>o</sup>]',
                 colourdata_max = 360, colourdata_min = 0, colourdata_step = 45,
                 filedata = 'log_smart_v_width')

    plotly_multi(x1data = np.log10(data['FL_GOES'].astype('float64')), x1title = 'log10 GOES Flux',
                 x2data = np.log10(data['FL_DURATION'].astype('float64')),  x2title = 'log10 Flare duration',
                 x3data = np.log10(data['SRS_NN'].astype('float64')), x3title = 'log10 SRS no. spots',
                 x4data = np.log10(data['SMART_TOTAREA'].astype('float64')), x4title = 'log10 Total area [m.s.h.]',
                 x5data = np.log10(data['SMART_TOTFLX'].astype('float64')), x5title = 'log10 Total flux [Mx]',
                 x6data = np.log10(data['SMART_BMEAN'].astype('float64')), x6title = 'log10 Bmean [G]',
                 x7data = np.log10(data['SMART_BIPOLESEP'].astype('float64')), x7title = 'log10 Bipole separation [Mm]',
                 x8data = data['SMART_RVALUE'].astype('float64'), x8title = 'log10 R value [Mx]',
                 x9data = data['SMART_WLSG'].astype('float64'), x9title = 'log10 WLsg [G/Mm]',
                 y1data = data['COR2_V'].astype('float64'), y1title = 'CME Speed [ms<sup>-1</sup>]',
                 y1range = [0, 2000],
                 weightdata = '10',
                 colourdata = np.log10(data['FL_GOES'].astype('float64')), colourdata_title = 'GOES Flux [Mx]',
                 colourdata_max = np.log10(1e-4), colourdata_min = np.log10(1e-7),
                 colourdata_step = np.log10(0.01),
                 filedata = 'log_smart_v_goes') #A to  X
#try log,e or natural log!

    # Output a .csv file with fixed data
    # data.to_csv('lowcat.csv')

    # Jordan's data
    # data = pd.read_json(FLARECAST_FILE)
    #
    # # Find elements of series that actually have data (either nans or dictionarys)
    # logic = np.ones(len(data['FC_data']))
    # for i in range(len(data['FC_data'])):
    #     if isinstance(data['FC_data'][i], float):
    #         logic[i] = 0
    # hub = data['FC_data'][logic == 1.].index
    # plotdata = data.iloc[hub,]
    # #[u'ising_energy_part_br', u'ising_energy_br', u'alpha_exp_cwt_btot', u'alpha_exp_cwt_blos',
    # # u'alpha_exp_fft_btot', u'alpha_exp_cwt_br', u'sharp_kw', u'r_value_br_logr', u'decay_index_blos',
    # # u'flow_field_bvec', u'alpha_exp_fft_br', u'r_value_blos_logr', u'mpil_br', u'beff_blos', u'decay_index_br',
    # # u'helicity_energy_bvec', u'wlsg_br', u'alpha_exp_fft_blos', u'mpil_blos', u'fc_data_q', u'ising_energy_blos']
    #
    #
    # plotly_multi(x1data = plotdata['FC_data']['r_value_blos_logr'], x1title = 'GOES FLux',
    #              x2data = plotdata['FC_data']['decay_index_blos']['tot_l_over_hmin'],  x2title = 'Flare duration',
    #              x3data = plotdata['FC_data']['ising_energy_blos']['ising_energy'], x3title = 'SRS no. spots',
    #              x4data = plotdata['FC_data']['mpil_blos']['tot_length'], x4title = 'Total area [m.s.h.]',
    #              x5data = plotdata['FC_data']['r_value_blos_logr'], x5title = 'Total flux [Mx]',
    #              x6data = plotdata['FC_data']['wlsg_blos']['value_int'], x6title = 'Bmean [G]',
    #              x7data = plotdata['FC_data']['flow_field_bvec']['vz_mean'], x7title = 'Bipole separation [Mm]',
    #              x8data = plotdata['FC_data']['helicity_energy_bvec']['abs_tot_dhdt_in'], x8title = 'log10 R value [Mx]',
    #              x9data = plotdata['FC_data']['frdim_err']['sfunction_Blos'], x9title = 'log10 WLsg [G/Mm]',
    #              y1data = plotdata['FC_data']['sharp_kw']['sflux']['total'],
    #              weightdata = '10',
    #              colourdata = plotdata['COR2_WIDTH'],
    #              filedata = 'flarecast_v_width')
    #
    # csvdata = pd.read_csv('/Users/sophie/flarecastcomma.csv')
    #
    # plotly_multi(x1data = csvdata['R Value Blos Logr'], x1title = 'Log R value blos',
    #              x2data = csvdata['tot l over hmin (FC data.decay index blos)'],  x2title = 'Tot decay index blos',
    #              x3data = csvdata['ising energy (FC data.ising energy blos)'], x3title = 'Ising energy blos',
    #              x4data = csvdata['tot length (FC data.mpil blos)'], x4title = 'Tot PIL length blos',
    #              x5data = csvdata['tot usflux (FC data.mpil blos)'], x5title='tot usflux blos',
    #              x6data = csvdata['Beff'], x6title = 'Beff',
    #              x7data = csvdata['Diver'], x7title='Diver',
    #              x8data = csvdata['W Shear'], x8title = 'W shear',
    #              x9data = csvdata['Tot Uns Dedt Sh'], x9title = 'Tot Uns Dedt Sh',
    #              y1data = csvdata['Cor2 V'],
    #              weightdata = '10',
    #              colourdata = csvdata['Cor2 Width'],
    #              filedata = 'flarecast_v_width')
    #
    # plotly_multi(x1data = csvdata['total (FC data.sharp kw.gamma)'], x1title = 'total sharp gamma)',
    #              x2data = csvdata['total (FC data.sharp kw.hgradbh)'],  x2title = 'total sharp hgradbh)',
    #              x3data = csvdata['total (FC data.sharp kw.hgradbz)'], x3title = 'total sharp hgradbz)',
    #              x4data = csvdata['total (FC data.sharp kw.hgradbt)'], x4title = 'total sharp hgradbt)',
    #              x5data = csvdata['total (FC data.sharp kw.snetjzpp)'], x5title = 'total sharp snetjzpp)',
    #              x6data = csvdata['total (FC data.sharp kw.twistp)'], x6title = 'total sharp twistp)',
    #              x7data = csvdata['total (FC data.sharp kw.usflux)'], x7title = 'total sharp usflux)',
    #              x8data = csvdata['total (FC data.sharp kw.usiz)'], x8title = 'total sharp usiz)',
    #              x9data = csvdata['total (FC data.sharp kw.ushz)'], x9title = 'total sharp ushz)',
    #              y1data = csvdata['Cor2 V'],
    #              weightdata = '10',
    #              colourdata = csvdata['Cor2 Width'],
    #              filedata = 'flarecast_sharp_v_width')

def fix_data(outstr):
    """Some data in the catalogue are in unfortunate format
    Here I'm converting them to something useful for plotting purposes"""
    # Make halo events an integer
    outstr["cor2_halo"][np.where(outstr["cor2_width"] < 120. )] = 1.
    outstr["cor2_halo"][np.where(outstr["cor2_width"] > 120.) and np.where(outstr["cor2_width"] > 270.)] = 2.
    outstr["cor2_halo"][np.where(outstr["cor2_width"] > 270.)] = 3.
    outstr["cor2_halo"][np.logical_not(outstr["cor2_width"] > 0.)] = np.nan
    # Convert GOES strings to magnitudes
    for i in range(len(outstr)):
        outstr["fl_goes"][i] = goes_string2mag(outstr["fl_goes"][i])
        # Get log 10 of R value and WLSGs
        if (outstr["SMART_RVALUE"][i] > 0.):
            outstr["SMART_RVALUE"][i] = np.log10(outstr["SMART_RVALUE"][i])
        if (outstr["SMART_WLSG"][i] > 0.):
            outstr["SMART_WLSG"][i] = np.log10(outstr["SMART_WLSG"][i])
        # Convert everything else to NaNs
        for j in range(len(outstr[i])):
            if outstr[i][j] == 0:
                outstr[i][j] = np.nan
    # Now get some datetimes
    outstr['FL_STARTTIME'] = get_dates(outstr['FL_STARTTIME'])
    outstr['FL_ENDTIME'] = get_dates(outstr['FL_ENDTIME'])
    outstr['FL_PEAKTIME'] = get_dates(outstr['FL_PEAKTIME'])
    return outstr


def goes_string2mag(goes):
    """Given a string of GOES class, in format 'M5.2',
    convert to a float with correct magnitude in Wm^(-2).
    If just a blank string then outputs a NaN instead.
    """
    # Skip any blank elements
    if (goes == ' ' or goes == ''):
        out = np.nan
    # Grab the GOES class and magnitude then convert
    else:
        goesclass = list(goes)[0]
        mag = float("".join(list(goes)[1:4]))
        #Combine to Wm^-2
        if goesclass == 'A':
            out = mag * 1.0e-8
        elif goesclass == 'B':
            out = mag * 1.0e-7
        elif goesclass == 'C':
            out = mag * 1.0e-6
        elif goesclass == 'M':
            out = mag * 1.0e-5
        elif goesclass == 'X':
            out = mag * 1.0e-4
    return out


def get_dates(data):
    """Get datetime structures for anything that has a time,
    otherwise just add NaNs"""
    for i in range(len(data)):
        if data[i] == ' ':
            data[i]  = float('NaN')
        else:
            data[i] = dt.datetime.strptime(data[i], '%d-%b-%Y %H:%M:%S.%f')
    return data


def calculate_flare_duration(data_start, data_end):
    """Get flare duration in minutes
    """
    data_out = data_end - data_start
    for i in range(len(data_out)):
        try:
            data_out[i] = (data_out[i]).total_seconds()/60.
        except AttributeError:
            continue
    return data_out


def try_bokeh(data):
    """trying the crossfilter eventually but simpler first"""
    data = pd.DataFrame(data)

    hale_colormap = {' ': 'black', '': 'black', '          NaN': 'black',
                    'Alpha': 'green', 'Beta':'turquoise',
                    'Gamma':'blue', 'Delta': 'navy',
                    'Beta-Gamma': 'purple', 'Beta-Gamma-Delta': 'magenta', 'Beta-Delta': 'pink'
                     }
    hale_colors = [hale_colormap[x] for x in data['SRS_HALE']]
    hale_colors = pd.Series(hale_colors)
    data['hale_colors'] = hale_colors.values
    scatter = Scatter(data, x='SMART_TOTAREA', y='FL_GOES',
                      color=hale_colors)

    halo_colormap = {' ': 'black', 'IV': 'purple'}
    halo_colors = [halo_colormap[x] for x in data['COR2_HALO']]
    halo_colors = pd.Series(halo_colors)
    data['halo_colors'] = halo_colors.values
    halo_colors = [halo_colormap[x] for x in data['halo_colors']]
    scat = Scatter(data, x='COR2_V', y='SMART_TOTFLX', color='halo_colors') #radius

    show(scatter)


def plotly_single(xdata, ydata, weightdata, colourdata, filedata):
    trace1 = go.Scatter(
        x=xdata,
        y=ydata,
        mode='markers',
        marker=dict(
            size=weightdata,
            color=colourdata,
            colorscale='Viridis',
            showscale=True
        )
    )
    data = [trace1]
    layout = go.Layout(
        xaxis=dict(
            type='log',
        ),
        yaxis=dict(
            type='linear',
        )
    )
    py.iplot(data=data, layout=layout, filename=filedata)


def plotly_multi(x1data, x1title,
                 x2data, x2title,
                 x3data, x3title,
                 x4data, x4title,
                 x5data, x5title,
                 x6data, x6title,
                 x7data, x7title,
                 x8data, x8title,
                 x9data, x9title,
                 y1data, y1title, y1range,
                 weightdata,
                 colourdata, colourdata_title,
                 colourdata_max, colourdata_min, colourdata_step,
                 filedata):
    """Make multi subplots in plotly
    """
    trace1 = get_plotly_trace(x1data, y1data,
                              weightdata, colourdata, colourdata_title,
                              colourdata_max, colourdata_min, colourdata_step,
                              showscale=True)
    trace2 = get_plotly_trace(x2data, y1data,
                              weightdata, colourdata, colourdata_title,
                              colourdata_max, colourdata_min, colourdata_step,
                              showscale=False)
    trace3 = get_plotly_trace(x3data, y1data,
                              weightdata, colourdata, colourdata_title,
                              colourdata_max, colourdata_min, colourdata_step,
                              showscale=False)
    trace4 = get_plotly_trace(x4data, y1data,
                              weightdata, colourdata, colourdata_title,
                              colourdata_max, colourdata_min, colourdata_step,
                              showscale=False)
    trace5 = get_plotly_trace(x5data, y1data,
                              weightdata, colourdata, colourdata_title,
                              colourdata_max, colourdata_min, colourdata_step,
                              showscale=False)
    trace6 = get_plotly_trace(x6data, y1data,
                              weightdata, colourdata, colourdata_title,
                              colourdata_max, colourdata_min, colourdata_step,
                              showscale=False)
    trace7 = get_plotly_trace(x7data, y1data,
                              weightdata, colourdata, colourdata_title,
                              colourdata_max, colourdata_min, colourdata_step,
                              showscale=False)
    trace8 = get_plotly_trace(x8data, y1data,
                              weightdata, colourdata, colourdata_title,
                              colourdata_max, colourdata_min, colourdata_step,
                              showscale=False)
    trace9 = get_plotly_trace(x9data, y1data,
                              weightdata, colourdata, colourdata_title,
                              colourdata_max, colourdata_min, colourdata_step,
                              showscale=False)
    fig = tools.make_subplots(rows=3, cols=3)
    fig.append_trace(trace1, 1, 1)
    fig.append_trace(trace2, 1, 2)
    fig.append_trace(trace3, 1, 3)
    fig.append_trace(trace4, 2, 1)
    fig.append_trace(trace5, 2, 2)
    fig.append_trace(trace6, 2, 3)
    fig.append_trace(trace7, 3, 1)
    fig.append_trace(trace8, 3, 2)
    fig.append_trace(trace9, 3, 3)
    fig['layout'].update(showlegend=False,
                         margin=dict(t=20,
                                     b=80,
                                     l=80,
                                     pad=0),
                         font=dict(size=12)
                         )
    fig['layout']['yaxis1'].update(type='linear',
                                   ticks='outside',
                                   showgrid=False,
                                   domain=[0.7, 0.95],
                                   autorange=False,
                                   range=y1range
                                   )
    fig['layout']['yaxis2'].update(type='linear',
                                   ticks='outside',
                                   showgrid=False,
                                   showticklabels=False,
                                   domain=[0.7, 0.95],
                                   autorange=False,
                                   range=y1range
                                   )
    fig['layout']['yaxis3'].update(type='linear',
                                   ticks='outside',
                                   showgrid=False,
                                   showticklabels=False,
                                   domain=[0.7, 0.95],
                                   autorange=False,
                                   range=y1range
                                   )
    fig['layout']['yaxis4'].update(type='linear',
                                   title=y1title,
                                   titlefont=dict(size=12),
                                   ticks='outside',
                                   showgrid=False,
                                   domain=[0.35, 0.6],
                                   autorange=False,
                                   range=y1range
                                   )
    fig['layout']['yaxis5'].update(type='linear',
                                   ticks='outside',
                                   showgrid=False,
                                   showticklabels=False,
                                   domain=[0.35, 0.6],
                                   autorange=False,
                                   range=y1range
                                   )
    fig['layout']['yaxis6'].update(type='linear',
                                   ticks='outside',
                                   showgrid=False,
                                   showticklabels=False,
                                   domain=[0.35, 0.6],
                                   autorange=False,
                                   range=y1range
                                   )
    fig['layout']['yaxis7'].update(type='linear',
                                   ticks='outside',
                                   showgrid=False,
                                   domain=[0, 0.25],
                                   autorange=False,
                                   range=y1range
                                   )
    fig['layout']['yaxis8'].update(type='linear',
                                   ticks='outside',
                                   showgrid=False,
                                   showticklabels=False,
                                   domain=[0, 0.25],
                                   autorange=False,
                                   range=y1range
                                   )
    fig['layout']['yaxis9'].update(type='linear',
                                   ticks='outside',
                                   showgrid=False,
                                   showticklabels=False,
                                   domain=[0, 0.25],
                                   autorange=False,
                                   range=y1range
                                   )
    fig['layout']['xaxis1'].update(type='linear',
                                   title = x1title,
                                   titlefont=dict(size=12),
                                   ticks = 'outside',
                                   showgrid=False,
                                   domain=[0.1, 0.35]
                                   )
    fig['layout']['xaxis2'].update(type='linear',
                                   title = x2title,
                                   titlefont=dict(size=12),
                                   ticks = 'outside',
                                   showgrid=False,
                                   domain=[0.4, 0.65]
                                   )
    fig['layout']['xaxis3'].update(type='linear',
                                   title = x3title,
                                   titlefont=dict(size=12),
                                   ticks = 'outside',
                                   showgrid=False,
                                   domain=[0.7, 0.95]
                                   )
    fig['layout']['xaxis4'].update(type='linear',
                                   title = x4title,
                                   titlefont=dict(size=12),
                                   ticks = 'outside',
                                   showgrid=False,
                                   domain=[0.1, 0.35]
                                   )
    fig['layout']['xaxis5'].update(type='linear',
                                   title = x5title,
                                   titlefont=dict(size=12),
                                   ticks = 'outside',
                                   showgrid=False,
                                   domain=[0.4, 0.65]
                                   )
    fig['layout']['xaxis6'].update(type='linear',
                                   title = x6title,
                                   titlefont=dict(size=12),
                                   ticks = 'outside',
                                   showgrid=False,
                                   domain=[0.7, 0.95]
                                   )
    fig['layout']['xaxis7'].update(type='linear',
                                   title = x7title,
                                   titlefont=dict(size=12),
                                   ticks = 'outside',
                                   showgrid=False,
                                   domain=[0.1, 0.35]
                                   )
    fig['layout']['xaxis8'].update(type='linear',
                                   title = x8title,
                                   titlefont=dict(size=12),
                                   ticks = 'outside',
                                   showgrid=False,
                                   domain=[0.4, 0.65]
                                   )
    fig['layout']['xaxis9'].update(type='linear',
                                   title = x9title,
                                   titlefont=dict(size=12),
                                   ticks = 'outside',
                                   showgrid=False,
                                   domain=[0.7, 0.95]
                                   )
    py.iplot(fig, filename=filedata)


def get_plotly_trace(xdata, ydata,
                     weightdata, colourdata, colourdata_title,
                     colourdata_max, colourdata_min, colourdata_step,
                     showscale):
    """Get trace for plotly subplot
    """
    return go.Scatter(x=xdata,
                      y=ydata,
                      mode='markers',
                      marker=dict(size=weightdata,
                                  color=colourdata,
                                  colorscale='Viridis',
                                  showscale=showscale,
                                  cauto=False,
                                  cmax=colourdata_max,
                                  cmin=colourdata_min,
                                  colorbar = dict(title=colourdata_title,
                                                  x=1.01,
                                                  y=0.47,
                                                  len=1,
                                                  thickness=25,
                                                  thicknessmode='pixels',
                                                  xpad=10,
                                                  ypad=10,
                                                  dtick=colourdata_step)
                                  )
                      )



if __name__ == '__main__':
    main()

