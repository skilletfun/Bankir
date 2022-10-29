import QtQuick 2.12
import QtQuick.Window 2.12
import QtQuick.Controls 2.12

Window {
    id: root

    property int current_act: 0
    property var finished_proc: []
    property var arr_for_processes: []

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

    RGrid {
        id: avail_ress
        anchors.top: parent.top
        anchors.topMargin: 60
        anchors.left: parent.left
        anchors.leftMargin: parent.width / 8
        width: parent.width / 3
        height: width
    }

    Rectangle {
        anchors.left: avail_ress.right
        anchors.right: parent.right
        anchors.rightMargin: 20
        anchors.leftMargin: 50
        anchors.top: parent.top
        anchors.topMargin: 60
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 60
        border.width: 1
        
        ListView {
            id: logs
            anchors.fill: parent
            anchors.leftMargin: 20
            anchors.topMargin: 20
            anchors.bottomMargin: 20
            clip: true
            spacing: 10
            model: logs_model
            delegate: Text {
                color: 'black'
                text: _text
                font.pointSize: 12
            }

            ListModel {
                id: logs_model
            }
        }
    }


    Button {
        id: start    
        enabled: false    
        anchors.left: avail_ress.left
        anchors.right: avail_ress.right
        anchors.top: avail_ress.bottom
        anchors.topMargin: 50
        anchors.leftMargin: 20
        anchors.rightMargin: 20
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
        interval: 1000
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
        timer.stop();
        start.enabled = true;
        finished_proc = [];
        rep.model = ['A', 'B', 'C', 'D']
        current_act = 0;
        avail_ress.mainmodel.clear();
        avail_ress.generate();
        logs_model.clear();
    }

    function solve() {
        // берем первый ресурс, находим первый процесс, который его требует, добавляем его (индекс клетки) в массив выполняемых
        // находим остальные процессы, которые требуют этот ресурс, добавляем их (индекс клетки) в массив отклоненных, переходим к след ресурсу
        // подсвечиваем все добавленные индексы желтым
        
        // подсвечиваем отклоненные красным, а выполняемые зеленым, после чего у выполняемых снижаем число на 1
        
        // начинаем цикл заново, сбросив у всех клеток цвета
        if (current_act == 0)
        {
            arr_for_processes = sort_processes();
            current_act += 1;
        }
        else if (current_act == 1)
        {
            colorize_processes();
            check_is_some_process_finished();
            current_act += 1;
        }
        else if (current_act == 2)
        {
            current_act = 0;
            clear();
            if (check_need_running()) solve();
            else reset();
        }
    }

    function sort_processes() {
        var m = avail_ress.mainmodel;
        var flag = true;
        var arr1 = [];      // работающие процессы, зеленым подсветить 
        var arr2 = [];      // ожидающие процессы, красным подсветить
        var running = [];   // процессы, которые уже затребовали ресурс
        for (var i = 0; i < 4; i++)
        {
            for (var j = 0; j < 4; j++)
            {
                var t = m.get(i + 4*j)._count;
                if (!running.includes(j))
                {
                    if (t > 0 && flag)
                    {
                        flag = false;
                        running.push(j);
                        arr1.push(i + 4*j);
                        colorize(i + 4*j, 'yellow');
                        logging('Process ' + ['A', 'B','C', 'D'][j] + ' requests resource ' + ['R1','R2','R3','R4'][i]);
                    }
                    else if (t > 0)
                    {
                        running.push(j);
                        colorize(i + 4*j, 'yellow');
                        arr2.push(i + 4*j);
                        logging('Process ' + ['A', 'B','C', 'D'][j] + ' requests resource ' + ['R1','R2','R3','R4'][i]);
                    }
                }
            }
            flag = true;
        }
        return [arr1, arr2];
    }

    function colorize_processes() {
        for (var i = 0; i < arr_for_processes[0].length; i++)
        {
            var index = arr_for_processes[0][i];
            colorize(index, 'green');
            logging('Running process ' + ['A', 'B','C', 'D'][Math.floor(index / 4)]);
            avail_ress.mainmodel.setProperty(index, '_count', avail_ress.mainmodel.get(index)._count-1);
        }
        for (var i = 0; i < arr_for_processes[1].length; i++)
        {
            var index = arr_for_processes[1][i];
            colorize(index, 'red');
            logging('Process ' + ['A', 'B','C', 'D'][Math.floor(index / 4)] +' paused');
        }
    }

    function logging(text) {
        logs_model.append({'_text': text});
        logs.positionViewAtIndex(logs_model.count-1, ListView.Visible);
    }

    function clear() {
        for (var i = 0; i < 16; i++) colorize(i, 'white');
    }

    function colorize(index, color) {
        avail_ress.mainmodel.setProperty(index, '_color', color);
    }

    function check_need_running() {
        for (var i = 0; i < 16; i++) if (avail_ress.mainmodel.get(i)._count > 0) return true;
        return false;
    }

    function check_is_some_process_finished() {
        var m = avail_ress.mainmodel;
        for (var i = 0; i < 4; i++)
        {
            var t = m.get(4*i)._count + m.get(1 + 4*i)._count + m.get(2 + 4*i)._count + m.get(3 + 4*i)._count;
            if (t == 0) finish_process(i);
        }
    }

    function finish_process(index) {
        if (!finished_proc.includes(index))
        {
            finished_proc.push(index);
            var m = rep.model;
            m[index] = m[index] + ' [' + String(finished_proc.length) + ']';
            rep.model = m;
            logging('Process ' + ['A', 'B','C', 'D'][index] + ' finished');
        }
    }

    function check() {
        var m = avail_ress.mainmodel;
        var b = true;
        for (var i = 0; i < 4; i++)
        {
            var t = m.get(4*i)._count + m.get(1 + 4*i)._count + m.get(2 + 4*i)._count + m.get(3 + 4*i)._count;
            if (t == 0) b = false;
        }
        return b;
   }
}