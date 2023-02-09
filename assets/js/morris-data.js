$(function() {

    Morris.Area({
        element: 'morris-area-chart',
        data: [{
            period: '2010 Q1',
            pixels: 2666,
            lotes: null,
            clientes: 2647
        }, {
            period: '2010 Q2',
            pixels: 2778,
            lotes: 2294,
            clientes: 2441
        }, {
            period: '2010 Q3',
            pixels: 4912,
            lotes: 1969,
            clientes: 2501
        }, {
            period: '2010 Q4',
            pixels: 3767,
            lotes: 3597,
            clientes: 5689
        }, {
            period: '2011 Q1',
            pixels: 6810,
            lotes: 1914,
            clientes: 2293
        }, {
            period: '2011 Q2',
            pixels: 5670,
            lotes: 4293,
            clientes: 1881
        }, {
            period: '2011 Q3',
            pixels: 4820,
            lotes: 3795,
            clientes: 1588
        }, {
            period: '2011 Q4',
            pixels: 15073,
            lotes: 5967,
            clientes: 5175
        }, {
            period: '2012 Q1',
            pixels: 10687,
            lotes: 4460,
            clientes: 2028
        }, {
            period: '2012 Q2',
            pixels: 8432,
            lotes: 5713,
            clientes: 1791
        }],
        xkey: 'period',
        ykeys: ['pixels', 'lotes', 'clientes'],
        labels: ['Pixels', 'Lotes', 'Clientes'],
        pointSize: 2,
        hideHover: 'auto',
        resize: true
    });

 
});
