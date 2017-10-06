'''
Created on 2017 May 11

@author: smurray

Python Version:    2.7.2 (default, Oct  1 2012, 15:56:20)
Working directory:     ~/GitHub/lowcat/vis

Description:

Notes:

'''

CAT_FOLDER = '/Users/sophie/Dropbox/lowcat/results/'
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
import cufflinks as cf

mpl.rc('font', size = 10, family = 'serif', weight='normal')
mpl.rc('legend', fontsize = 8)
mpl.rc('lines', linewidth = 1.5)

cm_data = [[0.2081, 0.1663, 0.5292], [0.2116238095, 0.1897809524, 0.5776761905],
           [0.212252381, 0.2137714286, 0.6269714286], [0.2081, 0.2386, 0.6770857143],
           [0.1959047619, 0.2644571429, 0.7279], [0.1707285714, 0.2919380952, 0.779247619],
           [0.1252714286, 0.3242428571, 0.8302714286], [0.0591333333, 0.3598333333, 0.8683333333],
           [0.0116952381, 0.3875095238, 0.8819571429], [0.0059571429, 0.4086142857, 0.8828428571],
           [0.0165142857, 0.4266, 0.8786333333], [0.032852381, 0.4430428571, 0.8719571429],
           [0.0498142857, 0.4585714286, 0.8640571429], [0.0629333333, 0.4736904762, 0.8554380952],
           [0.0722666667, 0.4886666667, 0.8467], [0.0779428571, 0.5039857143, 0.8383714286],
           [0.079347619, 0.5200238095, 0.8311809524], [0.0749428571, 0.5375428571, 0.8262714286],
           [0.0640571429, 0.5569857143, 0.8239571429], [0.0487714286, 0.5772238095, 0.8228285714],
           [0.0343428571, 0.5965809524, 0.819852381], [0.0265, 0.6137, 0.8135],
           [0.0238904762, 0.6286619048, 0.8037619048], [0.0230904762, 0.6417857143, 0.7912666667],
           [0.0227714286, 0.6534857143, 0.7767571429], [0.0266619048, 0.6641952381, 0.7607190476],
           [0.0383714286, 0.6742714286, 0.743552381], [0.0589714286, 0.6837571429, 0.7253857143],
           [0.0843, 0.6928333333, 0.7061666667], [0.1132952381, 0.7015, 0.6858571429],
           [0.1452714286, 0.7097571429, 0.6646285714], [0.1801333333, 0.7176571429, 0.6424333333],
           [0.2178285714, 0.7250428571, 0.6192619048], [0.2586428571, 0.7317142857, 0.5954285714],
           [0.3021714286, 0.7376047619, 0.5711857143], [0.3481666667, 0.7424333333, 0.5472666667],
           [0.3952571429, 0.7459, 0.5244428571], [0.4420095238, 0.7480809524, 0.5033142857],
           [0.4871238095, 0.7490619048, 0.4839761905], [0.5300285714, 0.7491142857, 0.4661142857],
           [0.5708571429, 0.7485190476, 0.4493904762], [0.609852381, 0.7473142857, 0.4336857143],
           [0.6473, 0.7456, 0.4188], [0.6834190476, 0.7434761905, 0.4044333333],
           [0.7184095238, 0.7411333333, 0.3904761905], [0.7524857143, 0.7384, 0.3768142857],
           [0.7858428571, 0.7355666667, 0.3632714286], [0.8185047619, 0.7327333333, 0.3497904762],
           [0.8506571429, 0.7299, 0.3360285714], [0.8824333333, 0.7274333333, 0.3217],
           [0.9139333333, 0.7257857143, 0.3062761905], [0.9449571429, 0.7261142857, 0.2886428571],
           [0.9738952381, 0.7313952381, 0.266647619], [0.9937714286, 0.7454571429, 0.240347619],
           [0.9990428571, 0.7653142857, 0.2164142857], [0.9955333333, 0.7860571429, 0.196652381],
           [0.988, 0.8066, 0.1793666667], [0.9788571429, 0.8271428571, 0.1633142857],
           [0.9697, 0.8481380952, 0.147452381], [0.9625857143, 0.8705142857, 0.1309],
           [0.9588714286, 0.8949, 0.1132428571], [0.9598238095, 0.9218333333, 0.0948380952],
           [0.9661, 0.9514428571, 0.0755333333], [0.9763, 0.9831, 0.0538]]


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
    df['COR2_TS'] = pd.to_datetime(df['COR2_TS'], format='%d-%b-%Y %H:%M:%S.%f')
    df['COR2_TF'] = pd.to_datetime(df['COR2_TF'], format='%d-%b-%Y %H:%M:%S.%f')
    df['COR2_DURATION'] = calculate_flare_duration(df['COR2_TS'], df['COR2_TF'])

    # CME property histograms
    #   barmode(overlay | group | stack)
    #   bins(int)
    #   histnorm('' | 'percent' | 'probability' | 'density' | 'probability density')
    #   histfunc('count' | 'sum' | 'avg' | 'min' | 'max')

    cf.set_config_file(offline=False, world_readable=True, theme='pearl')

    ##already made so commenting out
    # df['FL_GOES'] = np.log10(df['FL_GOES'].astype('float64'))
    # df_cme_hists = df[['COR2_WIDTH', 'COR2_V',
    #                    'FL_GOES', 'FL_DURATION']]
    # df_cme_hists.iplot(kind='histogram', subplots=True, shape=(2, 2),
    #                    filename='cmeflare_hist',
    #                    histnorm='percent')

    ##already made so commenting out
    # df_smart_hists = df[['SMART_TOTAREA', 'SMART_TOTFLX',
    #                    'SMART_BMIN', 'SMART_BMAX',
    #                    'SMART_PSLLEN', 'SMART_BIPOLESEP',
    #                    'SMART_RVALUE', 'SMART_WLSG']]
    # df_smart_hists.iplot(kind='histogram', subplots=True, shape=(4, 2),
    #                    filename='smart_hist',
    #                    histnorm='percent')

    csvdata = pd.read_csv(CAT_FOLDER+'fcastexc.csv')

    df_flarecast_hists = csvdata[['total (FC data.sharp kw.usiz)', 'Value Int', 'R Value Br Logr',
                             'total (FC data.sharp kw.usflux)', 'ave (FC data.sharp kw.ushz)', 'total (FC data.sharp kw.ushz)',
                             'ising energy (FC data.ising energy blos)', 'max (FC data.sharp kw.usiz)', 'Tot L Over Hmin',
                             'R Value Blos Logr', 'max (FC data.sharp kw.jz)', 'Alpha',
                             'ave (FC data.sharp kw.usflux)', 'ising energy (FC data.ising energy br)', 'ave (FC data.sharp kw.usiz)']]
    df_flarecast_hists.iplot(kind='histogram', subplots=True, shape=(5, 3),
                             filename='fcast_hist_final',
                             histnorm='percent')

    # messed with pandas and realised didnt have python 3
    # plt.figure()
    # ax1 = df.plot.scatter(x='SMART_RVALUE', y='COR2_V', c='COR2_WIDTH')
    # ax = df.plot.scatter(x='SMART_RVALUE', y='COR2_V', c='DarkBlue', label='B')
    # df.plot.scatter(x='SMART_RVALUE', y='COR2_V', c='DarkGreen', label='C', ax=ax)

    ##already made so commenting out
    # srs_area_complexity(df=df)

    #plot goes flux and wlsg halo
    plotly_double(x1data = np.log10(df['FL_GOES'].astype('float64')),  x1title = 'GOES Flux [Wm-2]',
                  x2data = df['SMART_WLSG'].astype('float64'), x2title='WLsg [G/Mm]',
                  y1data = np.log10(df['COR2_V'].astype('float64')), y1title = 'CME Speed [ms<sup>-1</sup>]',
                  y1range = [2, 3.2],
                  weightdata = '10',
                  colourdata = df['COR2_WIDTH'].astype('float64'), colourdata_title='CME width [<sup>o</sup>]',
                  colourdata_max=360, colourdata_min=0, colourdata_step=90,
                  filedata = 'halo_cme_properties_log10_colour',
                  colourscale='Viridis')

    ##already made so commenting out
    plotly_multi(x1data = np.log10(np.abs(df['SMART_BMIN'].astype('float64'))),  x1title = 'Bmin [G]',
                 x2data = np.log10(df['SMART_BMAX'].astype('float64')), x2title = 'Bmax [G]',
                 x3data = np.log10(df['SMART_TOTAREA'].astype('float64')), x3title='Total area [m.s.h]',
                 x4data = np.log10(df['SMART_TOTFLX'].astype('float64')), x4title='Total flux [Mx]',
                 x5data = df['SMART_RVALUE'].astype('float64'), x5title='R value [Mx]',
                 x6data = df['SMART_WLSG'].astype('float64'), x6title='WLsg [G/Mm]',
                 y1data = np.log10(df['COR2_V'].astype('float64')), y1title = 'CME Speed [kms<sup>-1</sup>]',
                 y1range = [2, 3.2],
                 weightdata = '10',
                 colourdata = np.log10(df['FL_GOES'].astype('float64')), colourdata_title = 'GOES Flux [Wm-2]',
                 colourdata_max = -3, colourdata_min = -7, colourdata_step = 1,
                 filedata = 'smart_properties_paper_log10',
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


def flux_area_complexity(df):
    """
    
    :return: 
    """

    sizecircle = 16

    # alpha = df['SRS_HALE'].loc[df["SRS_HALE"] == 'Alpha']
    # beta = df['SRS_HALE'].loc[df["SRS_HALE"] == 'Beta']
    # beta-gamma = df['SRS_HALE'].loc[df["SRS_HALE"] == 'Beta-Gamma']
    # beta-delta = df['SRS_HALE'].loc[df["SRS_HALE"] == 'Beta-Delta']
    # beta-gamma-delta = df['SRS_HALE'].loc[df["SRS_HALE"] == 'Beta-Gamma-Delta']

    fig, (ax1, ax2) = plt.subplots(1,2, sharey=True)

    fig.subplots_adjust(left = 0.1, right = 0.95, bottom = 0.1, top = 0.5, wspace = 0.2, hspace = 0.65)

    alpha=ax1.scatter(x=np.log10((df['SMART_TOTAREA'].loc[df["SRS_HALE"] == 'Alpha']).astype('float64')),
                y=np.log10((df['FL_GOES'].loc[df["SRS_HALE"] == 'Alpha']).astype('float64')),
                            s=sizecircle, c='black',
                            lw = 0)
    beta=ax1.scatter(x=np.log10((df['SMART_TOTAREA'].loc[df["SRS_HALE"] == 'Beta']).astype('float64')),
                y=np.log10((df['FL_GOES'].loc[df["SRS_HALE"] == 'Beta']).astype('float64')),
                            s=sizecircle, c='darkblue',
                            lw = 0)
    bg=ax1.scatter(x=np.log10((df['SMART_TOTAREA'].loc[df["SRS_HALE"] == 'Beta-Gamma']).astype('float64')),
                y=np.log10((df['FL_GOES'].loc[df["SRS_HALE"] == 'Beta-Gamma']).astype('float64')),
                            s=sizecircle, c='dodgerblue',
                            lw = 0)
    bd=ax1.scatter(x=np.log10((df['SMART_TOTAREA'].loc[df["SRS_HALE"] == 'Beta-Delta']).astype('float64')),
                y=np.log10((df['FL_GOES'].loc[df["SRS_HALE"] == 'Beta-Delta']).astype('float64')),
                            s=sizecircle, c='darkcyan',
                            lw = 0)
    bgd=ax1.scatter(x=np.log10((df['SMART_TOTAREA'].loc[df["SRS_HALE"] == 'Beta-Gamma-Delta']).astype('float64')),
                y=np.log10((df['FL_GOES'].loc[df["SRS_HALE"] == 'Beta-Gamma-Delta']).astype('float64')),
                            s=sizecircle, c='y',
                            lw = 0)
    ax1.set_xlabel(r'log10 SMART Total Area [m.s.h]')
    ax1.set_ylabel(r'log10 GOES Flux [Wm$^{-2}$]')
    ax1.legend((alpha,beta,bg,bd,bgd),(r'$\alpha$',r'$\beta$',r'$\beta\gamma$',r'$\beta\delta$',r'$\beta\gamma\delta$'))
    ax1.set_xlim([1, 4])
    ax1.set_ylim([-8, -2])

    ax2.scatter(x=np.log10((df['SRS_AREA'].loc[df["SRS_HALE"] == 'Alpha']).astype('float64')),
                y=np.log10((df['FL_GOES'].loc[df["SRS_HALE"] == 'Alpha']).astype('float64')),
                            s=sizecircle, c='black',
                            lw = 0)
    ax2.scatter(x=np.log10((df['SRS_AREA'].loc[df["SRS_HALE"] == 'Beta']).astype('float64')),
                y=np.log10((df['FL_GOES'].loc[df["SRS_HALE"] == 'Beta']).astype('float64')),
                            s=sizecircle, c='darkblue',
                            lw = 0)
    ax2.scatter(x=np.log10((df['SRS_AREA'].loc[df["SRS_HALE"] == 'Beta-Gamma']).astype('float64')),
                y=np.log10((df['FL_GOES'].loc[df["SRS_HALE"] == 'Beta-Gamma']).astype('float64')),
                            s=sizecircle, c='dodgerblue',
                            lw = 0)
    ax2.scatter(x=np.log10((df['SRS_AREA'].loc[df["SRS_HALE"] == 'Beta-Delta']).astype('float64')),
                y=np.log10((df['FL_GOES'].loc[df["SRS_HALE"] == 'Beta-Delta']).astype('float64')),
                            s=sizecircle, c='darkcyan',
                            lw = 0)
    ax2.scatter(x=np.log10((df['SRS_AREA'].loc[df["SRS_HALE"] == 'Beta-Gamma-Delta']).astype('float64')),
                y=np.log10((df['FL_GOES'].loc[df["SRS_HALE"] == 'Beta-Gamma-Delta']).astype('float64')),
                            s=sizecircle, c='y',
                            lw = 0)
    ax2.set_xlabel(r'log10 SRS Area [m.s.h]')
    ax2.set_xlim([0, 4])
    ax2.set_ylim([-8, -2])

    fig.savefig('goes_area.eps', format='eps', dpi=1200)


def fl_flare_plot(df):
    """dsdsd
    """
    ydata = df['COR2_V'].astype('float64')

    sizecircle = 16

    bounds = np.array([-7, -6, -5, -4, -3])
    cdata = np.log10(df['FL_GOES'].astype('float64'))
    vmin = -7.
    vmax = -3.
    cm = LinearSegmentedColormap.from_list('parula', cm_data)

    fig, (ax1, ax2) = plt.subplots(1,2, sharey=True)

    fig.subplots_adjust(left = 0.05, right = 0.9, bottom = 0.1, top = 0.5, wspace = 0.2, hspace = 0.65)

    im = ax1.scatter(x = np.log10(df['FL_GOES'].astype('float64')), y=ydata,
                            s=sizecircle, c=cdata,
                            cmap=cm, norm=mpl.colors.BoundaryNorm(boundaries=bounds, ncolors=256),
                            lw = 0)
    ax1.set_xlabel(r'GOES Flux')
    ax1.set_yscale('log')
    ax1.set_xlim([-8, -3])

    ax2.scatter(x = np.log10(df['FL_DURATION'].astype('float64')), y=ydata,
                       s=sizecircle, c=cdata,
                       cmap=cm, norm=mpl.colors.BoundaryNorm(boundaries=bounds, ncolors=256),
                       lw=0)
    ax2.set_xlabel(r'Flare duration')
    ax2.set_yscale('log')
    ax2.set_xlim([0, 3])


    fig.savefig('flare_flare.eps', format='eps', dpi=1200)

def fl_halo_plot(df):
    """dsdsd
    """
    ydata = df['COR2_V'].astype('float64')

    sizecircle = 16

    cdata = df['COR2_WIDTH']
    vmin = 0.
    vmax = 360.
    cm = plt.cm.get_cmap('viridis')

    fig, (ax1, ax2) = plt.subplots(1,2, sharey=True)

    fig.subplots_adjust(left = 0.05, right = 0.9, bottom = 0.1, top = 0.5, wspace = 0.2, hspace = 0.65)

    im = ax1.scatter(x = np.log10(df['FL_GOES'].astype('float64')), y=ydata,
                            s=sizecircle, c=cdata,
                            cmap=cm, norm=mpl.colors.Normalize(vmin=vmin, vmax=vmax),
                            lw = 0)
    ax1.set_xlabel(r'GOES Flux')
    ax1.set_yscale('log')
    ax1.set_xlim([-8, -3])

    ax2.scatter(x = np.log10(df['FL_DURATION'].astype('float64')), y=ydata,
                       s=sizecircle, c=cdata,
                       cmap=cm, norm=mpl.colors.Normalize(vmin=vmin, vmax=vmax),
                       lw=0)
    ax2.set_xlabel(r'Flare duration')
    ax2.set_yscale('log')
    ax2.set_xlim([0, 3])


    fig.savefig('flare_halo.eps', format='eps', dpi=1200)

def srs_flare_plot(df):
    """dsdsd
    """
    ydata = df['COR2_V'].astype('float64')
    ymin = 0.
    ymax = 1500.

    sizecircle = 16

    bounds = np.array([-7, -6, -5, -4, -3])
    cdata = np.log10(df['FL_GOES'].astype('float64'))
    vmin = -7.
    vmax = -3.
    cm = LinearSegmentedColormap.from_list('parula', cm_data)

    fig, (ax1, ax2, ax3) = plt.subplots(1,3, sharey=True)

    fig.subplots_adjust(left = 0.05, right = 0.9, bottom = 0.1, top = 0.5, wspace = 0.2, hspace = 0.65)

    im = ax1.scatter(x = np.log10(df['SRS_AREA'].astype('float64')), y=ydata,
                            s=sizecircle, c=cdata,
                            cmap=cm, norm=mpl.colors.BoundaryNorm(boundaries=bounds, ncolors=256),
                            lw = 0)
    ax1.set_xlabel(r'Area [m.s.h.]')
    ax1.set_yscale('log')
    ax1.set_xlim([0, 4])

    ax2.scatter(x = np.log10(df['SRS_LL'].astype('float64')), y=ydata,
                       s=sizecircle, c=cdata,
                       cmap=cm, norm=mpl.colors.BoundaryNorm(boundaries=bounds, ncolors=256),
                       lw=0)
    ax2.set_xlabel(r'Longitudinal extent [$^{\circ}$]')
    ax2.set_yscale('log')
    ax2.set_xlim([0, 2])

    ax3.scatter(x = np.log10(df['SRS_NN'].astype('float64')), y=ydata,
                       s=sizecircle, c=cdata,
                       cmap=cm, norm=mpl.colors.BoundaryNorm(boundaries=bounds, ncolors=256),
                       lw=0)
    ax3.set_xlabel(r'No. visible spots')
    ax3.set_yscale('log')
    ax3.set_xlim([0, 3])

    fig.savefig('srs_flare.eps', format='eps', dpi=1200)

def srs_halo_plot(df):
    """dsdsd
    """
    ydata = df['COR2_V'].astype('float64')

    sizecircle = 16

    cdata = df['COR2_WIDTH']
    vmin = 0.
    vmax = 360.
    cm = plt.cm.get_cmap('viridis')

    fig, (ax1, ax2, ax3) = plt.subplots(1,3, sharey=True)

    fig.subplots_adjust(left = 0.05, right = 0.9, bottom = 0.1, top = 0.5, wspace = 0.2, hspace = 0.65)

    im = ax1.scatter(x = np.log10(df['SRS_AREA'].astype('float64')), y=ydata,
                            s=sizecircle, c=cdata,
                            cmap=cm, norm=mpl.colors.Normalize(vmin=vmin, vmax=vmax),
                            lw = 0)
    ax1.set_xlabel(r'Area [m.s.h.]')
    ax1.set_yscale('log')
    ax1.set_xlim([0, 4])

    ax2.scatter(x = np.log10(df['SRS_LL'].astype('float64')), y=ydata,
                       s=sizecircle, c=cdata,
                       cmap=cm, norm=mpl.colors.Normalize(vmin=vmin, vmax=vmax),
                       lw=0)
    ax2.set_xlabel(r'Longitudinal extent [$^{\circ}$]')
    ax2.set_yscale('log')
    ax2.set_xlim([0, 2])

    ax3.scatter(x = np.log10(df['SRS_NN'].astype('float64')), y=ydata,
                       s=sizecircle, c=cdata,
                       cmap=cm, norm=mpl.colors.Normalize(vmin=vmin, vmax=vmax),
                       lw=0)
    ax3.set_xlabel(r'No. visible spots')
    ax3.set_yscale('log')
    ax3.set_xlim([0, 3])

    fig.savefig('srs_halo.eps', format='eps', dpi=1200)

def smart_flare_plot(df):
    """dsdsd
    """
    ydata = df['COR2_V'].astype('float64')
    ymin = 0.
    ymax = 1500.

    sizecircle = 16

    bounds = np.array([-7, -6, -5, -4, -3])
    cdata = np.log10(df['FL_GOES'].astype('float64'))
    vmin = -7.
    vmax = -3.
    cm = LinearSegmentedColormap.from_list('parula', cm_data)

    fig, axes = plt.subplots(nrows=4, ncols=2, sharey='row')

    # fig.subplots_adjust(left = 0.08, right = 1.02, bottom = 0.08, top = 0.98, wspace = 0.25, hspace = 0.5)
    fig.subplots_adjust(left = 0.35, right = .9, bottom = 0.1, top = 0.98, wspace = 0.3, hspace = 0.65)

    im = axes[0, 0].scatter(x = np.log10(np.abs(df['SMART_BMIN'].astype('float64'))), y=ydata,
                            s=sizecircle, c=cdata,
                            cmap=cm, norm=mpl.colors.BoundaryNorm(boundaries=bounds, ncolors=256),
                            lw = 0)
    axes[0, 0].set_xlabel(r'B$_\mathrm{{min}}$ [G]')
    axes[0, 0].set_xlim([2.5, 4])
    axes[0, 0].set_xticks([2.5, 3, 3.5, 4])

    axes[0, 1].scatter(x = np.log10(df['SMART_BMAX'].astype('float64')), y=ydata,
                       s=sizecircle, c=cdata,
                       cmap=cm, norm=mpl.colors.BoundaryNorm(boundaries=bounds, ncolors=256),
                       lw=0) #norm=mpl.colors.Normalize(vmin=vmin, vmax=vmax
    axes[0, 1].set_xlabel(r'B$_\mathrm{{max}}$ [G]')
    axes[0, 1].set_xlim([2.5, 4])
    axes[0, 1].set_xticks([2.5, 3, 3.5, 4])


    axes[1, 0].scatter(x = np.log10(df['SMART_TOTAREA'].astype('float64')), y=ydata,
                       s=sizecircle, c=cdata,
                       cmap=cm, norm=mpl.colors.Normalize(vmin=vmin, vmax=vmax),
                       lw=0)
    axes[1, 0].set_xlabel(r'Total area [m.s.h]')
    axes[1, 0].set_xlim([1, 4])
    axes[1, 0].set_xticks([1, 2, 3, 4])


    axes[1, 1].scatter(x = np.log10(df['SMART_TOTFLX'].astype('float64')), y=ydata,
                       s=sizecircle, c=cdata,
                       cmap=cm, norm=mpl.colors.Normalize(vmin=vmin, vmax=vmax),
                       lw=0)
    axes[1, 1].set_xlabel(r'Total flux [Mx]')
    axes[1, 1].set_xlim([21, 24])
    axes[1, 1].set_xticks([21, 22, 23, 24])

    axes[2, 0].scatter(x = np.log10(df['SMART_PSLLEN'].astype('float64')), y = ydata,
                       s=sizecircle, c = cdata,
                       cmap=cm, norm=mpl.colors.Normalize(vmin=vmin, vmax=vmax),
                       lw=0)
    axes[2, 0].set_xlabel(r'PSL length [Mm]')
    axes[2, 0].set_xlim([0,4])
    axes[2, 0].set_xticks([0, 1, 2, 3, 4])
    axes[2, 0].set_ylabel(r'                              CME speed [kms$^{-1}$]')

    axes[2, 1].scatter(x = np.log10(df['SMART_BIPOLESEP'].astype('float64')), y = ydata,
                       s=sizecircle, c = cdata,
                       cmap=cm, norm=mpl.colors.Normalize(vmin=vmin, vmax=vmax),
                       lw=0)
    axes[2, 1].set_xlabel(r'Bipole separation [Mm]')
    axes[2, 1].set_xlim([0,3])
    axes[2, 1].set_xticks([0, 1, 2, 3])

    axes[3, 0].scatter(x = df['SMART_RVALUE'].astype('float64'), y = ydata,
                       s=sizecircle, c = cdata,
                       cmap=cm, norm=mpl.colors.Normalize(vmin=vmin, vmax=vmax),
                       lw=0)
    axes[3, 0].set_xlabel(r'R value [Mx]')
    axes[3, 0].set_xlim([3,7])
    axes[3, 0].set_xticks([3, 4, 5, 6, 7])

    axes[3, 1].scatter(x = df['SMART_WLSG'].astype('float64'), y = ydata,
                       s=sizecircle, c = cdata,
                       cmap=cm, norm=mpl.colors.Normalize(vmin=vmin, vmax=vmax),
                       lw=0)
    axes[3, 1].set_xlabel(r'WLsg [GMm$^{-1}$]')
    axes[3, 1].set_xlim([2,7])

    for ax in axes.flat:
        ax.set_ylim([ymin, ymax])
        ax.set_yscale('log')
    cb = fig.colorbar(im, ax=axes.ravel().tolist(), aspect=20)
    cb.set_label(r"CME width [$^{\circ}$]")
    # cb.ax.xaxis.set_ticks_position('top')
    # cb.ax.xaxis.set_label_position('top')
    #, shrink=0.75

    fig.savefig('smart_flare.eps', format='eps', dpi=1200)

def smart_halo_plot(df):
    """dsdsd
    """
    ydata = df['COR2_V'].astype('float64')
    ymin = 0.
    ymax = 1500.

    sizecircle = 16

    cdata = df['COR2_WIDTH']
    vmin = 0.
    vmax = 360.
    cm = plt.cm.get_cmap('viridis')

    fig, axes = plt.subplots(nrows=4, ncols=2, sharey='row')

    # fig.subplots_adjust(left = 0.08, right = 1.02, bottom = 0.08, top = 0.98, wspace = 0.25, hspace = 0.5)
    fig.subplots_adjust(left = 0.35, right = .9, bottom = 0.1, top = 0.98, wspace = 0.3, hspace = 0.65)

    im = axes[0, 0].scatter(x = np.log10(np.abs(df['SMART_BMIN'].astype('float64'))), y=ydata,
                            s=sizecircle, c=cdata,
                            cmap=cm, norm=mpl.colors.Normalize(vmin=vmin, vmax=vmax),
                            lw = 0)
    axes[0, 0].set_xlabel(r'B$_\mathrm{{min}}$ [G]')
    axes[0, 0].set_xlim([2.5, 4])
    axes[0, 0].set_xticks([2.5, 3, 3.5, 4])

    axes[0, 1].scatter(x = np.log10(df['SMART_BMAX'].astype('float64')), y=ydata,
                       s=sizecircle, c=cdata,
                       cmap=cm, norm=mpl.colors.Normalize(vmin=vmin, vmax=vmax),
                       lw=0)
    axes[0, 1].set_xlabel(r'B$_\mathrm{{max}}$ [G]')
    axes[0, 1].set_xlim([2.5, 4])
    axes[0, 1].set_xticks([2.5, 3, 3.5, 4])


    axes[1, 0].scatter(x = np.log10(df['SMART_TOTAREA'].astype('float64')), y=ydata,
                       s=sizecircle, c=cdata,
                       cmap=cm, norm=mpl.colors.Normalize(vmin=vmin, vmax=vmax),
                       lw=0)
    axes[1, 0].set_xlabel(r'Total area [m.s.h]')
    axes[1, 0].set_xlim([1, 4])
    axes[1, 0].set_xticks([1, 2, 3, 4])


    axes[1, 1].scatter(x = np.log10(df['SMART_TOTFLX'].astype('float64')), y=ydata,
                       s=sizecircle, c=cdata,
                       cmap=cm, norm=mpl.colors.Normalize(vmin=vmin, vmax=vmax),
                       lw=0)
    axes[1, 1].set_xlabel(r'Total flux [Mx]')
    axes[1, 1].set_xlim([21, 24])
    axes[1, 1].set_xticks([21, 22, 23, 24])

    axes[2, 0].scatter(x = np.log10(df['SMART_PSLLEN'].astype('float64')), y = ydata,
                       s=sizecircle, c = cdata,
                       cmap=cm, norm=mpl.colors.Normalize(vmin=vmin, vmax=vmax),
                       lw=0)
    axes[2, 0].set_xlabel(r'PSL length [Mm]')
    axes[2, 0].set_xlim([0,4])
    axes[2, 0].set_xticks([0, 1, 2, 3, 4])
    axes[2, 0].set_ylabel(r'                              CME speed [kms$^{-1}$]')

    axes[2, 1].scatter(x = np.log10(df['SMART_BIPOLESEP'].astype('float64')), y = ydata,
                       s=sizecircle, c = cdata,
                       cmap=cm, norm=mpl.colors.Normalize(vmin=vmin, vmax=vmax),
                       lw=0)
    axes[2, 1].set_xlabel(r'Bipole separation [Mm]')
    axes[2, 1].set_xlim([0,3])
    axes[2, 1].set_xticks([0, 1, 2, 3])

    axes[3, 0].scatter(x = df['SMART_RVALUE'].astype('float64'), y = ydata,
                       s=sizecircle, c = cdata,
                       cmap=cm, norm=mpl.colors.Normalize(vmin=vmin, vmax=vmax),
                       lw=0)
    axes[3, 0].set_xlabel(r'R value [Mx]')
    axes[3, 0].set_xlim([3,7])
    axes[3, 0].set_xticks([3, 4, 5, 6, 7])

    axes[3, 1].scatter(x = df['SMART_WLSG'].astype('float64'), y = ydata,
                       s=sizecircle, c = cdata,
                       cmap=cm, norm=mpl.colors.Normalize(vmin=vmin, vmax=vmax),
                       lw=0)
    axes[3, 1].set_xlabel(r'WLsg [GMm$^{-1}$]')
    axes[3, 1].set_xlim([2,7])

    for ax in axes.flat:
        ax.set_ylim([ymin, ymax])
        ax.set_yscale('log')
    cb = fig.colorbar(im, ax=axes.ravel().tolist())
    cb.set_label(r"CME width [$^{\circ}$]")
    # cb.ax.xaxis.set_ticks_position('top')
    # cb.ax.xaxis.set_label_position('top')
    #, shrink=0.75

    fig.savefig('smart_halo.eps', format='eps', dpi=1200)

    # axes[0, 2].scatter(x = df['SMART_BMEAN'].astype('float64'), y=ydata,
    #                    s=sizecircle, c=cdata,
    #                    cmap=cm, norm=mpl.colors.Normalize(vmin=vmin, vmax=vmax),
    #                    lw=0)
    # axes[0, 2].set_xlabel('Bmean')
    # axes[0, 2].set_xlim([-100, 100])

    # axes[0, 2].scatter(x = np.log10(df['SMART_POSAREA'].astype('float64')), y=ydata,
    #                    s=sizecircle, c=cdata,
    #                    cmap=cm, norm=mpl.colors.Normalize(vmin=vmin, vmax=vmax),
    #                    lw=0)
    # axes[0, 2].set_xlabel('+ve area')
    # axes[0, 2].set_xlim([0, 4])
    # axes[0, 2].set_xticks([0, 1, 2, 3, 4])
    #
    # axes[0, 3].scatter(x = np.log10(df['SMART_NEGAREA'].astype('float64')), y=ydata,
    #                    s=sizecircle, c=cdata,
    #                    cmap=cm, norm=mpl.colors.Normalize(vmin=vmin, vmax=vmax),
    #                    lw=0)
    # axes[0, 3].set_xlabel('-ve area')
    # axes[0, 3].set_xlim([0, 4])
    # axes[0, 3].set_xticks([0, 1, 2, 3, 4])
    #
    # axes[1, 1].scatter(x = np.log10(df['SMART_NEGFLX'].astype('float64')), y=ydata,
    #                    s=sizecircle, c=cdata,
    #                    cmap=cm, norm=mpl.colors.Normalize(vmin=vmin, vmax=vmax),
    #                    lw=0)
    # axes[1, 1].set_xlabel('-ve Flux')
    # axes[1, 1].set_xlim([20, 24])
    # axes[1, 1].set_xticks([20, 21, 22, 23, 24])
    #
    # axes[1, 2].scatter(x = np.log10(df['SMART_POSFLX'].astype('float64')), y=ydata,
    #                    s=sizecircle, c=cdata,
    #                    cmap=cm, norm=mpl.colors.Normalize(vmin=vmin, vmax=vmax),
    #                    lw=0)
    # axes[1, 2].set_xlabel('+ve Flux')
    # axes[1, 2].set_xlim([20, 24])
    # axes[1, 2].set_xticks([20, 21, 22, 23, 24])
    #
    # axes[1, 3].scatter(x = np.log10(df['SMART_FRCFLX'].astype('float64')), y=ydata,
    #                    s=sizecircle, c=cdata,
    #                    cmap=cm, norm=mpl.colors.Normalize(vmin=vmin, vmax=vmax),
    #                    lw=0)
    # axes[1, 3].set_xlabel('abs Flux Fraction')
    # axes[1, 3].set_xlim([-5, 0])



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

def  plotly_hist_double(x1, x2, title):
    """Get hists stacked on top of each other
    """
    trace1 = go.Histogram(x=df['COR2_V'].astype('float64'), opacity=0.75)
    trace2 = go.Histogram(x=df['COR2_WIDTH'].astype('float64'), opacity=0.75)
    data = [trace1, trace2]
    layout = go.Layout(barmode='overlay')
    fig = go.Figure(data=data, layout=layout)
    py.iplot(fig, filename='cme_v_width_hist')



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

