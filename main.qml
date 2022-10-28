import QtQuick 2.12
import QtQuick.Window 2.12
import QtQuick.Controls 2.12

Window {
    id: root

    property int current_proc: 0
    property int current_res: 0
    property int current_act: 0
    property var finished_proc: []
    property var tried_proc: []
    property int errors: 0

    width: 900
    height: 600
    minimumWidth: 900
    maximumWidth: 900
    maximumHeight: 900
    minimumHeight: 600 
    visible: true
    title: qsTr("BANKIR")
    color: '#EEF9DF'
    
    Row {
        anchors.bottom: avail_ress.top
        anchors.bottomMargin: 10
        anchors.left: avail_ress.left
        anchors.leftMargin: avail_ress.cellWidth / 2 - 14
        spacing: avail_ress.cellWidth/2 + 8
        Repeater {
            model: [1,2,3,4]
            delegate: Text {
                font.pointSize: 14
                text: 'R' + String(modelData)
            }
        }
    }

    Row {
        anchors.bottom: require_ress.top
        anchors.bottomMargin: 10
        anchors.left: require_ress.left
        anchors.leftMargin: require_ress.cellWidth / 2 - 14
        spacing: require_ress.cellWidth/2 + 8
        Repeater {
            model: [1,2,3,4]
            delegate: Text {
                font.pointSize: 14
                text: 'R' + String(modelData)
            }
        }
    }

    Column {
        anchors.top: avail_ress.top
        anchors.topMargin: avail_ress.cellWidth / 2 - 7
        anchors.left: parent.left
        anchors.leftMargin: 50
        spacing: avail_ress.cellWidth/2 + 7
        Repeater {
            id: rep
            model: ['A', 'B', 'C', 'D']
            delegate: Text {
                font.pointSize: 14
                text: modelData
            }
        }
    }

    Column {
        anchors.top: require_ress.top
        anchors.topMargin: avail_ress.cellWidth / 2 - 7
        anchors.right: require_ress.left
        anchors.rightMargin: 10
        spacing: avail_ress.cellWidth/2 + 7
        Repeater {
            model: ['A', 'B', 'C', 'D']
            delegate: Text {
                font.pointSize: 14
                text: modelData
            }
        }
    }

    Text {
        text: 'Предоставлено ресурсов'
        font.pointSize: 15
        anchors.bottom: avail_ress.top
        anchors.bottomMargin: 70
        anchors.horizontalCenter: avail_ress.horizontalCenter
    }

    RGrid {
        id: avail_ress
        anchors.top: parent.top
        anchors.topMargin: 120
        anchors.left: parent.left
        anchors.leftMargin: parent.width / 8
        width: parent.width / 3
        height: width
    }

    Text {
        text: 'Максимальная потребность'
        font.pointSize: 15
        anchors.bottom: require_ress.top
        anchors.bottomMargin: 70
        anchors.horizontalCenter: require_ress.horizontalCenter
    }

    RGrid {
        id: require_ress
        anchors.top: parent.top
        anchors.topMargin: 120
        anchors.right: parent.right
        anchors.rightMargin: parent.width / 8
        width: parent.width / 3
        height: width
        do_check_start_button: false
    }

    Button {
        id: start
        anchors.left: avail_ress.horizontalCenter
        anchors.right: require_ress.horizontalCenter
        anchors.top: avail_ress.bottom
        anchors.topMargin: 50
        height: 70
        background: Rectangle { border.width: 1; radius: 20; color: start.down ? 'grey' : 'white' }
        Text {
            id: starttext
            color: parent.enabled ? 'black' : 'grey'
            anchors.centerIn: parent
            text: 'Start'
            font.pointSize: 14
        }
        onReleased: {
            if (starttext.text == 'Start')
            {
                timer.start();
                enabled = false;
            }
            else
            {
                reset();
                starttext.text = 'Start';
            }
        }
    }

    Timer {
        id: timer
        interval: 500
        repeat: true
        onTriggered: {
            solve();
            if (finished_proc.length == 4)
            {
                stop();
                start.enabled = true;
                starttext.text = 'Reset';
            }
        }
    }

    function reset() {
        start.enabled = true;
        finished_proc = [];
        tried_proc = [];
        rep.model = ['A', 'B', 'C', 'D']
        current_act = 0;
        current_proc = 0;
        current_res = 0;
        errors = 0;
        avail_ress.mainmodel.clear();
        require_ress.mainmodel.clear();
        avail_ress.generate();
        require_ress.generate();
    }

    function solve() {
        // берем первый процесс, берем выделенные ему ресурсы + доступные и сравниваем с необходимыми для каждого ресурса
        if (current_act == 0)
        {
            // Подсвечиваем желтым
            compare();
            current_act += 1;
        }
        else if (current_act == 1)
        {
            // Сравниваем. Или зеленый, или красный. Если зеленый, то на шаг выше. В противном случае след шаг
            compare_result();
        }
        else if (current_act == 2)
        {
            // Если процессу не хватает ресурсов, сброс и поиск другого процесса
            clear();
            errors += 1;
            if (errors == 4-finished_proc.length)
            {
                timer.stop();
                reset();
            }
            else
            {
                tried_proc.push(current_proc);
                find_proc();
                current_res = 0;
                current_act = 0;
            }
        }
    }

    function compare_result() {
        var available = avail_ress.mainmodel.get(current_proc*4 + current_res)._count;
        var require = require_ress.mainmodel.get(current_proc*4 + current_res)._count;
        if (available + get_free_res() >= require) var color = 'green';
        else var color = 'red';
        colorize(avail_ress.mainmodel, current_proc*4 + current_res, color);
        colorize(require_ress.mainmodel, current_proc*4 + current_res, color);
        // Если все ок, то чекаем след ресурс, если нет, то переходим к шагу очистки
        if (color == 'green'){ current_res += 1; current_act -= 1; }
        else current_act += 1;
        // Если оказывается, что это был последний ресурс, то находим следующий незавершенный процесс, а ресурс обнуляем
        if (current_res == 4) do_free_proc();
    }

    function do_free_proc() {
        console.log('Process ' + String(current_proc) + ' finished');
        errors = 0;
        // Освободить ресурсы процесса
        take_ress();
        // Ресурс счетчик обнулить
        current_res = 0;
        // Добавить процесс в завершенные
        finished_proc.push(current_proc);
        var m = rep.model;
        m[current_proc] = m[current_proc] + ' [' + String(finished_proc.length) + ']';
        rep.model = m;
        // Найти след процесс для работы
        find_proc();
    }

    function take_ress() {
        var m = avail_ress.mainmodel;
        for (var i = 0; i < 4; i++) m.setProperty(current_proc*4 + i, '_count', 0);
        tried_proc = [];
    }

    function clear() {
        for (var i = 0; i < 4; i++)
        {
            colorize(avail_ress.mainmodel, current_proc*4 + i, 'white');
            colorize(require_ress.mainmodel, current_proc*4 + i, 'white');
        }
    }

    function find_proc() {
        console.log('Find next process for compute...');
        for (var i = 0; i < 4; i++)
        {
            if (!finished_proc.includes(i) && !tried_proc.includes(i))
            {
                if (check_proc()) 
                {
                    finished_proc.push(i);
                    current_proc = i;
                    do_free_proc();
                }
                console.log('Next process: ' + String(i+1));
                current_proc = i;
                break;
            }
        }
    }

    function check_proc() {
        var m = require_ress.mainmodel;
        return m.get(current_proc*4)._count + m.get(current_proc*4+1)._count + m.get(current_proc*4+2)._count + m.get(current_proc*4+3)._count == 0;
    }

    function compare() {
        if (require_ress.mainmodel.get(current_proc*4 + current_res)._count > 0)
        {
            console.log('Request ' + String(current_res+1) + ' resource for ' + String(current_proc+1) + ' process')
            colorize(avail_ress.mainmodel, current_proc*4 + current_res, 'yellow');
            colorize(require_ress.mainmodel, current_proc*4 + current_res, 'yellow');
        }
        else
        {
            if (current_res == 3) { 
                do_free_proc();
            }
            else {
                current_res += 1;
            }
            if (current_proc*4 + current_res != 15) compare();
        }
    }

    function colorize(model, index, color) {
        model.setProperty(index, '_color', color);
    }

    function get_free_res() {
        var m = avail_ress.mainmodel;
        var res = 0;
        for (var i = 0; i < 4; i++) res += m.get(i*4+current_res)._count;
        return 4-res;
    }

    function check() {
        return ((avail_ress.mainmodel.get(0)._count + avail_ress.mainmodel.get(4)._count + avail_ress.mainmodel.get(8)._count + avail_ress.mainmodel.get(12)._count <= 4) && (avail_ress.mainmodel.get(1)._count + avail_ress.mainmodel.get(5)._count + avail_ress.mainmodel.get(9)._count + avail_ress.mainmodel.get(13)._count <= 4) && (avail_ress.mainmodel.get(2)._count + avail_ress.mainmodel.get(6)._count + avail_ress.mainmodel.get(10)._count + avail_ress.mainmodel.get(14)._count <= 4) && (avail_ress.mainmodel.get(3)._count + avail_ress.mainmodel.get(7)._count + avail_ress.mainmodel.get(11)._count + avail_ress.mainmodel.get(15)._count <= 4))
    }
}