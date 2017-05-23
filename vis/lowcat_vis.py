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

import numpy as np
import datetime as dt
from scipy.io.idl import readsav
import pandas as pd
# import json
# from bokeh.charts import Scatter, output_file, show
# from glue import qglue
import plotly.graph_objs as go
import plotly.plotly as py


def main():
    """Loads the LOWCAT catalogue, 
    fixes some data formats,
    then loads the glue GUI to play around with the plots"""
    #load data
    savfile = readsav(CAT_FOLDER+SAV_FILE)
    #data = pd.read_json(CAT_FOLDER + JSON_FILE)

    #fix some of the data into a format that is more suitable
    outstr = fix_data(savfile['outstr'])
    data = pd.DataFrame(outstr)

    #visualise!
    #try_bokeh(outstr)
    #qglue(data1=outstr)
    try_plotly(xdata = data['SMART_RVALUE'], ydata = data['COR2_V'],
               weightdata = '16', colourdata = data['COR2_WIDTH'],
               filedata = 'trying_colour_weight_plot')

    plot_hist()
    #output a csv
    data.to_csv('lowcat.csv')

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


def try_bokeh(data):
    """trying the crossfilter eventually but simpler first"""
    data = pd.DataFrame(data)

    hale_colormap = {' ': 'black', '': 'black', '          NaN': 'black',
                    'Alpha': 'green', 'Beta':'turquoise',
                    'Gamma':'blue', 'Delta': 'navy',
                    'Beta-Gamma': 'purple', 'Beta-Gamma-Delta': 'magenta', 'Beta-Delta': 'pink'}
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

def try_plotly(xdata, ydata, weightdata, colourdata, filedata):
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
    layoutinfo = go.Layout(
        xaxis=dict(
            type='log',
        ),
        yaxis=dict(
            type='linear',
        )
    )
    py.iplot(data=data, layout=layout, filename=filedata)


# def fix_data(data):
#     """Some data in the catalogue are in unfortunate format
#     Here I'm converting them to something useful for plotting purposes"""
#     # Make halo events an integer
#     data.is_copy = False
#     data["COR2_HALO"].loc[data["COR2_HALO"] == 'II'] = 2.
#     data["COR2_HALO"].loc[data["COR2_HALO"] == 'III'] = 3.
#     data["COR2_HALO"].loc[data["COR2_HALO"] == 'IV'] = 4.
#     # Convert GOES strings to magnitudes
#     for i in range(len(data["FL_GOES"])):
#         print i
#         data["FL_GOES"][i] = goes_string2mag(data["FL_GOES"][i])
#     # Convert everything else to NaNs
#     for i in data.columns.tolist():
#         print i
#         for j in range(len(data[i])):
#             if data[i][j] == 0:
#                 data[i][j] = float('NaN')
#     return data

if __name__ == '__main__':
    main()

