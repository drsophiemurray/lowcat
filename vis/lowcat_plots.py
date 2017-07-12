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

#from lowcat_plots import *
import numpy as np
import datetime as dt
from scipy.io.idl import readsav
import pandas as pd
import matplotlib.pyplot as plt
import matplotlib as mpl
from matplotlib.colors import LinearSegmentedColormap
import plotly.graph_objs as go
import plotly.plotly as py
from plotly import tools

mpl.rc('font', size = 10, family = 'serif', weight='normal')
mpl.rc('legend', fontsize = 8)
mpl.rc('lines', linewidth = 1.5)


def main():
    """Loads the LOWCAT catalogue, 
    fixes some data formats,
    then loads the glue GUI to play around with the plots"""
    # Load the .sav file
    savfile = readsav(CAT_FOLDER+SAV_FILE)

    # Fix some of the data into a format that is more suitable
    outstr = fix_data(savfile['outstr'])
    df = pd.DataFrame(outstr)

    # Calculate flare duration
    df['FL_DURATION'] = calculate_flare_duration(df['FL_STARTTIME'], df['FL_ENDTIME'])

    #sammis tang plot
    srs_area_complexity(df=df)

    # cme speed vs width
    plotly_double(x1data = np.log10(df['COR2_WIDTH'].astype('float64')),  x1title = 'CME Width',
                  x2data = df['COR2_WIDTH'].astype('float64'), x2title='CME Width',
                  y1data = df['COR2_V'], y1title = 'CME Speed [ms<sup>-1</sup>]',
                  y1range = [0, 2000],
                  weightdata = '10',
                  colourdata = df['COR2_PA'].astype('float64'), colourdata_title='CME PA [<sup>o</sup>]',
                  colourdata_max=0, colourdata_min=360, colourdata_step=45,
                  filedata = 'cme-plots',
                  colourscale = 'Viridis')

    # plot goes flux and wlsg halo
    plotly_double(x1data = np.log10(df['FL_GOES'].astype('float64')),  x1title = 'GOES Flux [Wm-2]',
                  x2data = df['SMART_WLSG'].astype('float64'), x2title='WLsg [G/Mm]',
                  y1data = df['COR2_V'], y1title = 'CME Speed [ms<sup>-1</sup>]',
                  y1range = [0, 2000],
                  weightdata = '10',
                  colourdata = df['COR2_WIDTH'].astype('float64'), colourdata_title='CME width [<sup>o</sup>]',
                  colourdata_max=360, colourdata_min=0, colourdata_step=45,
                  filedata = 'halo_cme_properties',
                  colourscale = 'Viridis')

    # now with the goes colour bar
    plotly_multi(x1data = np.log10(np.abs(df['SMART_BMIN'].astype('float64'))),  x1title = 'Bmin [G]',
                 x2data = np.log10(df['SMART_BMAX'].astype('float64')), x2title = 'Bmax [G]',
                 x3data = np.log10(df['SMART_TOTAREA'].astype('float64')), x3title='Total area [m.s.h]',
                 x4data = np.log10(df['SMART_TOTFLX'].astype('float64')), x4title='Total flux [Mx]',
                 x5data = np.log10(df['SMART_PSLLEN'].astype('float64')), x5title='PSL length [Mm]',
                 x6data = df['SMART_RVALUE'].astype('float64'), x6title='R value [Mx]',
                 y1data = df['COR2_V'], y1title = 'CME Speed [kms<sup>-1</sup>]',
                 y1range = [0, 2000],
                 weightdata = '10',
                 colourdata = np.log10(df['FL_GOES'].astype('float64')), colourdata_title = 'GOES Flux [Wm-2]',
                 colourdata_max = -3, colourdata_min = -7, colourdata_step = 1,
                 filedata = 'smart_properties_cmespeed',
                 colourscale=[[0, 'rgb(54,50,153)'],
                              [0.25, 'rgb(54,50,153)'],
                              [0.25, 'rgb(17,123,215)'],
                              [0.5, 'rgb(17,123,215)'],
                              [0.5, 'rgb(37,180,167)'],
                              [0.75, 'rgb(37,180,167)'],
                              [0.75, 'rgb(249,210,41)'],
                              [1.0, 'rgb(249,210,41)']]
                 )

    #to get this working had to open in tableau, choose ones I wanted, save as csv, open in excel then save as csv again comma separated options
    csvdata = pd.read_csv(CAT_FOLDER+'flarecast_data_comma.csv')

    # flarecast halo
    plotly_multi(x1data = np.log10(csvdata['total (FC data.sharp kw.usiz)'].astype('float64')),  x1title = 'SHARP Total USIZ',
                 x2data = np.log10(csvdata['Value Int'].astype('float64')), x2title = 'Br WLSG',
                 x3data = csvdata['R Value Br Logr'].astype('float64'), x3title='Br R value',
                 x4data = np.log10(csvdata['total (FC data.sharp kw.usflux)'].astype('float64')), x4title='SHARP Total USFLUX',
                 x5data = np.log10(csvdata['total (FC data.sharp kw.ushz)'].astype('float64')), x5title='SHARP Total USHZ',
                 x6data = np.log10(csvdata['Ising Energy'].astype('float64')), x6title='Blos Ising Energy',
                 y1data = csvdata['Cor2 V'], y1title = 'CME Speed [kms<sup>-1</sup>]',
                 y1range = [0, 2000],
                 weightdata = '10',
                 colourdata = csvdata['Cor2 Width'].astype('float64'), colourdata_title='CME width [<sup>o</sup>]',
                 colourdata_max=360, colourdata_min=0, colourdata_step=45,
                 filedata = 'flarecast_top_properties_halo',
                 colourscale = 'Viridis'
                 )

    #convert the goes strings to numbers
    csvdata["Fl Goes"].loc[(csvdata["Fl Goes"].isnull())] = ' '
    for i in range(len(csvdata["Fl Goes"])):
        csvdata["Fl Goes"][i] = goes_string2mag(csvdata["Fl Goes"][i])

    plotly_multi(x1data = np.log10(csvdata['total (FC data.sharp kw.usiz)'].astype('float64')),  x1title = 'SHARP Total USIZ',
                 x2data = np.log10(csvdata['Value Int'].astype('float64')), x2title = 'Br WLSG',
                 x3data = csvdata['R Value Br Logr'].astype('float64'), x3title='Br R value',
                 x4data = np.log10(csvdata['total (FC data.sharp kw.usflux)'].astype('float64')), x4title='SHARP Total USFLUX',
                 x5data = np.log10(csvdata['total (FC data.sharp kw.ushz)'].astype('float64')), x5title='SHARP Total USHZ',
                 x6data = np.log10(csvdata['Ising Energy'].astype('float64')), x6title='Blos Ising Energy',
                 y1data = csvdata['Cor2 V'], y1title = 'CME Speed [kms<sup>-1</sup>]',
                 y1range = [0, 2000],
                 weightdata = '10',
                 colourdata = np.log10(csvdata['Fl Goes'].astype('float64')), colourdata_title = 'GOES Flux [Wm-2]',
                 colourdata_max = -3, colourdata_min = -7, colourdata_step = 1,
                 filedata = 'flarecast_top_properties_goes',
                 colourscale=[[0, 'rgb(54,50,153)'],
                              [0.25, 'rgb(54,50,153)'],
                              [0.25, 'rgb(17,123,215)'],
                              [0.5, 'rgb(17,123,215)'],
                              [0.5, 'rgb(37,180,167)'],
                              [0.75, 'rgb(37,180,167)'],
                              [0.75, 'rgb(249,210,41)'],
                              [1.0, 'rgb(249,210,41)']]
                 )


def srs_area_complexity(df):
    """

    :return: 
    """

    sizecircle = 30

    # alpha = df['SRS_HALE'].loc[df["SRS_HALE"] == 'Alpha']
    # beta = df['SRS_HALE'].loc[df["SRS_HALE"] == 'Beta']
    # beta-gamma = df['SRS_HALE'].loc[df["SRS_HALE"] == 'Beta-Gamma']
    # beta-delta = df['SRS_HALE'].loc[df["SRS_HALE"] == 'Beta-Delta']
    # beta-gamma-delta = df['SRS_HALE'].loc[df["SRS_HALE"] == 'Beta-Gamma-Delta']

    fig, ax2 = plt.subplots(1, 1)

    alpha = ax2.scatter(x=np.log10((df['SRS_AREA'].loc[df["SRS_HALE"] == 'Alpha']).astype('float64')),
                y=np.log10((df['FL_GOES'].loc[df["SRS_HALE"] == 'Alpha']).astype('float64')),
                s=sizecircle, c='black',
                lw=0)
    beta = ax2.scatter(x=np.log10((df['SRS_AREA'].loc[df["SRS_HALE"] == 'Beta']).astype('float64')),
                y=np.log10((df['FL_GOES'].loc[df["SRS_HALE"] == 'Beta']).astype('float64')),
                s=sizecircle, c='darkblue',
                lw=0)
    bg = ax2.scatter(x=np.log10((df['SRS_AREA'].loc[df["SRS_HALE"] == 'Beta-Gamma']).astype('float64')),
                y=np.log10((df['FL_GOES'].loc[df["SRS_HALE"] == 'Beta-Gamma']).astype('float64')),
                s=sizecircle, c='dodgerblue',
                lw=0)
    bd = ax2.scatter(x=np.log10((df['SRS_AREA'].loc[df["SRS_HALE"] == 'Beta-Delta']).astype('float64')),
                y=np.log10((df['FL_GOES'].loc[df["SRS_HALE"] == 'Beta-Delta']).astype('float64')),
                s=sizecircle, c='darkcyan',
                lw=0)
    bgd = ax2.scatter(x=np.log10((df['SRS_AREA'].loc[df["SRS_HALE"] == 'Beta-Gamma-Delta']).astype('float64')),
                y=np.log10((df['FL_GOES'].loc[df["SRS_HALE"] == 'Beta-Gamma-Delta']).astype('float64')),
                s=sizecircle, c='y',
                lw=0)
    ax2.set_xlabel(r'log10 SRS Area [m.s.h]')
    ax2.set_xlim([0, 4])
    ax2.set_ylim([-8, -2])
    ax2.set_ylabel(r'log10 GOES Flux [Wm$^{-2}$]')
    ax2.legend((alpha, beta, bg, bd, bgd),
               (r'$\alpha$', r'$\beta$', r'$\beta\gamma$', r'$\beta\delta$', r'$\beta\gamma\delta$'))

    fig.savefig('goes_srs_area.eps', format='eps', dpi=1200)


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


def get_plotly_trace(xdata, ydata,
                     weightdata, colourdata, colourdata_title,
                     colourdata_max, colourdata_min, colourdata_step,
                     showscale, colourscale):
    """Get trace for plotly subplot
    """
    return go.Scatter(x=xdata,
                      y=ydata,
                      mode='markers',
                      marker=dict(size=weightdata,
                                  color=colourdata,
                                  colorscale=colourscale,
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


def plotly_multi(x1data, x1title,
                 x2data, x2title,
                 x3data, x3title,
                 x4data, x4title,
                 x5data, x5title,
                 x6data, x6title,
                 y1data, y1title, y1range,
                 weightdata,
                 colourdata, colourdata_title,
                 colourdata_max, colourdata_min, colourdata_step,
                 filedata, colourscale):
    """Make multi subplots in plotly
    """
    trace1 = get_plotly_trace(x1data, y1data,
                              weightdata, colourdata, colourdata_title,
                              colourdata_max, colourdata_min, colourdata_step,
                              showscale=True, colourscale=colourscale)
    trace2 = get_plotly_trace(x2data, y1data,
                              weightdata, colourdata, colourdata_title,
                              colourdata_max, colourdata_min, colourdata_step,
                              showscale=False, colourscale=colourscale)
    trace3 = get_plotly_trace(x3data, y1data,
                              weightdata, colourdata, colourdata_title,
                              colourdata_max, colourdata_min, colourdata_step,
                              showscale=False, colourscale=colourscale)
    trace4 = get_plotly_trace(x4data, y1data,
                              weightdata, colourdata, colourdata_title,
                              colourdata_max, colourdata_min, colourdata_step,
                              showscale=False, colourscale=colourscale)
    trace5 = get_plotly_trace(x5data, y1data,
                              weightdata, colourdata, colourdata_title,
                              colourdata_max, colourdata_min, colourdata_step,
                              showscale=False, colourscale=colourscale)
    trace6 = get_plotly_trace(x6data, y1data,
                              weightdata, colourdata, colourdata_title,
                              colourdata_max, colourdata_min, colourdata_step,
                              showscale=False, colourscale=colourscale)
    fig = tools.make_subplots(rows=3, cols=2)
    fig.append_trace(trace1, 1, 1)
    fig.append_trace(trace2, 1, 2)
    fig.append_trace(trace3, 2, 1)
    fig.append_trace(trace4, 2, 2)
    fig.append_trace(trace5, 3, 1)
    fig.append_trace(trace6, 3, 2)
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
                                   domain=[.7, 0.95],
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
                                   title=y1title,
                                   titlefont=dict(size=12),
                                   showgrid=False,
                                   domain=[0.35, 0.6],
                                   autorange=False,
                                   range=y1range
                                   )
    fig['layout']['yaxis4'].update(type='linear',
                                   ticks='outside',
                                   showgrid=False,
                                   showticklabels=False,
                                   domain=[0.35, 0.6],
                                   autorange=False,
                                   range=y1range
                                   )
    fig['layout']['yaxis5'].update(type='linear',
                                   ticks='outside',
                                   showgrid=False,
                                   domain=[0., 0.25],
                                   autorange=False,
                                   range=y1range
                                   )
    fig['layout']['yaxis6'].update(type='linear',
                                   ticks='outside',
                                   showgrid=False,
                                   showticklabels=False,
                                   domain=[0., 0.25],
                                   autorange=False,
                                   range=y1range
                                   )
    fig['layout']['xaxis1'].update(type='linear',
                                   title = x1title,
                                   titlefont=dict(size=12),
                                   ticks = 'outside',
                                   showgrid=False,
                                   domain=[0.4, 0.65]
                                   )
    fig['layout']['xaxis2'].update(type='linear',
                                   title = x2title,
                                   titlefont=dict(size=12),
                                   ticks = 'outside',
                                   showgrid=False,
                                   domain=[0.7, 0.95]
                                   )
    fig['layout']['xaxis3'].update(type='linear',
                                   title = x3title,
                                   titlefont=dict(size=12),
                                   ticks = 'outside',
                                   showgrid=False,
                                   domain=[0.4, 0.65]
                                   )
    fig['layout']['xaxis4'].update(type='linear',
                                   title = x4title,
                                   titlefont=dict(size=12),
                                   ticks = 'outside',
                                   showgrid=False,
                                   domain=[0.7, 0.95]
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
    py.iplot(fig, filename=filedata)


def plotly_double(x1data, x1title,
                 x2data, x2title,
                 y1data, y1title, y1range,
                 weightdata,
                 colourdata, colourdata_title,
                 colourdata_max, colourdata_min, colourdata_step,
                 filedata, colourscale):
    """Make multi subplots in plotly
    """
    trace1 = get_plotly_trace(x1data, y1data,
                              weightdata, colourdata, colourdata_title,
                              colourdata_max, colourdata_min, colourdata_step,
                              showscale=True, colourscale=colourscale)
    trace2 = get_plotly_trace(x2data, y1data,
                              weightdata, colourdata, colourdata_title,
                              colourdata_max, colourdata_min, colourdata_step,
                              showscale=False, colourscale=colourscale)
    fig = tools.make_subplots(rows=1, cols=2)
    fig.append_trace(trace1, 1, 1)
    fig.append_trace(trace2, 1, 2)
    fig['layout'].update(showlegend=False,
                         margin=dict(t=20,
                                     b=80,
                                     l=80,
                                     pad=0),
                         font=dict(size=12)
                         )
    fig['layout']['yaxis1'].update(type='linear',
                                   ticks='outside',
                                   title=y1title,
                                   titlefont=dict(size=12),
                                   showgrid=False,
                                   domain=[0.0, 0.4],
                                   autorange=False,
                                   range=y1range
                                   )
    fig['layout']['yaxis2'].update(type='linear',
                                   ticks='outside',
                                   showgrid=False,
                                   showticklabels=False,
                                   domain=[0.0, 0.4],
                                   autorange=False,
                                   range=y1range
                                   )
    fig['layout']['xaxis1'].update(type='linear',
                                   title = x1title,
                                   titlefont=dict(size=12),
                                   ticks = 'outside',
                                   showgrid=False,
                                   domain=[0.15, 0.55]
                                   )
    fig['layout']['xaxis2'].update(type='linear',
                                   title = x2title,
                                   titlefont=dict(size=12),
                                   ticks = 'outside',
                                   showgrid=False,
                                   domain=[0.6, 1.0]
                                   )
    py.iplot(fig, filename=filedata)


if __name__ == '__main__':
    main()

