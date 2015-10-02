import csv

def CommentStripper(iterator):
    for line in iterator:
        if line.startswith('# p'):
            continue
        if line.startswith('# GPAW'):
            continue
        if line.startswith('     32'):
            continue
        if line.startswith('     64'):
            continue
        yield line

# extraxt the run information: description line and results on 16 cores for all runs from analyse.txt
rows = []
for row in csv.reader(CommentStripper(open('analyse.txt', 'rb'))):
    if len(row) > 0:
        rows.append(row)
assert len(rows) % 2 == 0

# ID, 16 core price/hour in USD, total time in sec, price of the 16 cores run in USD cents, cpu type
runs = {}
for index in range(0, len(rows) - 1, 2):
    price = eval(rows[index][0].split()[3])  # price per hour
    cpu = rows[index][2].strip()
    time = eval(rows[index + 1][0].split()[-3].strip())
    total_price = time / 3600 * price * 100
    runs[rows[index][0].split()[2]] = (price, time, total_price, cpu)

ids = sorted(runs.keys())

# write plot data in csv format
with open('plot.csv', 'w') as csvfile:
    fieldnames = ['ID',
                  '16 core price/hour in USD',
                  'total time in sec',
                  'price of the 16 cores run in USD cents',
                  'cpu type']
    writer = csv.DictWriter(csvfile, fieldnames=fieldnames)

    writer.writeheader()
    for id in ids:
        row = {fieldnames[0]: id}
        for n, field in enumerate(fieldnames[1:]):
            row.update({field: runs[id][n]})
        writer.writerow(row)

labels = [id.replace('xeon16.openblas.SL', 'Niflheim') for id in ids]

import matplotlib
matplotlib.use('Agg')

from matplotlib import pylab

colors = ('k', 'b', 'g', 'y', 'c', 'w', 'm', 'r')

scale = [l + 0.5 for l in range(len(labels))]

zero = [0.0 for v in scale]
v0010 = [10.0 for v in scale]
v0020 = [20.0 for v in scale]
v0030 = [30.0 for v in scale]
v0050 = [50.0 for v in scale]
v0100 = [100.0 for v in scale]
v0500 = [500.0 for v in scale]
v0800 = [800.0 for v in scale]
v0900 = [900.0 for v in scale]
v1000 = [1000.0 for v in scale]

if 0:
    pylab.plot(scale, zero, 'k-', label='_nolegend_')
    pylab.plot(v0010, zero, 'k-', label='_nolegend_')
    pylab.plot(v0020, zero, 'k-', label='_nolegend_')
    pylab.plot(v0020, zero, 'k-', label='_nolegend_')
    pylab.plot(v0050, zero, 'k-', label='_nolegend_')
    pylab.plot(v0500, zero, 'k-', label='_nolegend_')
    pylab.plot(v0800, zero, 'k-', label='_nolegend_')
    pylab.plot(v0900, zero, 'k-', label='_nolegend_')
    pylab.plot(v1000, zero, 'k-', label='_nolegend_')

pylab.gca().set_ylim(-0.1, 1100.1)
pylab.gca().set_xlim(-0.1, max(scale) + 0.5 + 0.1)

if 0:  # print vertical lines at xticks
    # http://matplotlib.org/examples/pylab_examples/axhspan_demo.html
    for s in scale:
        l = pylab.axvline(x=s, linewidth=0.5, color=(0,0,0,0), alpha=0.5)

ay1 = pylab.gca()
ay1.xaxis.set_ticks([n for n in scale])
ay1.xaxis.set_ticklabels(labels)
ay1.yaxis.set_ticks([10., 50., 100., 500., 800., 900., 1000.,])
ay1.yaxis.set_ticklabels(['10', '50', '100', '500', '800', '900', '1000'])

for label in ay1.get_xticklabels() + ay1.get_yticklabels():
    label.set_fontsize(12)
# rotate labels http://old.nabble.com/Rotate-x-axes-%28xticks%29-text.-td3141258.html
for n, label in enumerate(ay1.get_xticklabels()):
    label.set_rotation(70)
    # label.set_position((0.0, 1.0 * (n % 2)))  # once up / once down
    label.set_position((0.0, 0.0))  # down

# create bins
time = [runs[id][1] for id in ids]
price = [runs[id][2] for id in ids]

width = 0.6
plotscale = [s - width/2 for s in scale]

plots = []
plots.append(pylab.bar(plotscale, price, width, color=colors[0], alpha=1.0))
plots.append(pylab.bar(plotscale, time, width, color=colors[1], alpha=0.3))

pylab.ylabel('Performance')
t = pylab.title('GPAW benchmark on 16 CPU cores')
# http://old.nabble.com/More-space-between-title-and-secondary-x-axis-td31722298.html
t.set_y(1.05)

prop = matplotlib.font_manager.FontProperties(size=12)
leg = pylab.legend(plots, ['price of the run in USD cents',
                           'run time in seconds'],
                           fancybox=True, prop=prop)
leg.get_frame().set_alpha(0.5)
# http://www.mail-archive.com/matplotlib-users@lists.sourceforge.net/msg03952.html
leg._loc=(0.40, 0.85)

pylab.savefig('plot.png', bbox_inches='tight', dpi=600)
