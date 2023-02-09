// Utiilities


/***********************************************************/
// List js creation calls
/**********************************************************/

function createTable(container, header, arr, arr_callb, obj) {
    obj = $.extend(true, {
        search: true,
        pagination: true,
        no_data_title:"No data to show",
        rowCallback:function(id){}
    }, obj);

    var search_val = $('#' + container + '_search').val();
    $('#' + container).empty();

    var ContentList = '<table class="list-group table" id="elements_list" ><thead id="' + container + '_table_head"></thead><tbody class="list" id="' + container + '_table_body"></tbody></table>';

    if (obj.search) {
        ContentList = '<div class="col-md-12 input-group"><input class="form-control input-sm search" name="search" placeholder="Search" type="text" id="' + container + '_search" /></div>' + ContentList;
    }

    if (obj.pagination) {
        ContentList = ContentList + '<ul class="pagination"></ul>';
    }

    $('#' + container).html(ContentList);

    var th_row = '';
    var values = [];
    for (var i = 0; i < header.length; i++) {
        th_row += '<th class="sort" data-sort="data_' + i + '">' + header[i] + '</th>';
        values.push('data_' + i);
    }
    $('#' + container + '_table_head').append('<tr>' + th_row + '</tr>');

    if (arr.length === 0) {
        var tr = $('<tr>');
        var td = $('<td colspan="' + header.length + '">');
        td.append(obj.no_data_title);
        tr.append(td);
        $('#' + container + '_table_body').append(tr);
    }

    for (var i = 0; i < arr.length; i++) {
        var tr = $('<tr>');
        tr.attr('data-id', arr[i].id);

        if (arr[i].active === true)
            tr.addClass('active');

        for (var j = 0; j < arr[i].data.length; j++) {
            var td = $('<td class="data_' + j + '">');
            td.append(arr[i].data[j]);

            if (typeof arr_callb === 'function') {
                td.addClass('element_list_item');
                td.click(arr_callb);
            } else if (arr_callb !== null && typeof arr_callb[j] !== 'undefined' && arr_callb[j] !== null) {
                td.addClass('element_list_item');
                td.click(arr_callb[j]);
            }
            td.attr('data-id', arr[i].id);
            td.attr('data-value', arr[i].value);

            tr.append(td);
        }

        $('#' + container + '_table_body').append(tr);
    }
    ;

    var options = {
        valueNames: values
    };

    if (obj.pagination) {
        options.plugins = [ListPagination({})];
        options.page = 10;
    }

    var list = new List(container, options);

    if (obj.search) {
        $('#' + container + '_search').val(search_val);
        list.search(search_val);
    }
    return list;
}
