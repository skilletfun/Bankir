import QtQuick 2.12
import QtQuick.Controls 2.12

GridView {
    id: root
    cellWidth: width / 4
    cellHeight: height / 4
    model: _model
    interactive: false
    property bool do_check_start_button: true

    property alias mainmodel: _model

    delegate: MouseArea {
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        width: root.cellWidth
        height: root.cellHeight
        Rectangle{
            anchors.fill: parent
            anchors.margins: 3
            border.width: 1
            color: parent.containsPress ? 'grey' : _color
        }
        Text {
            text: _count
            anchors.centerIn: parent
            font.pointSize: 14
        }
        onClicked: {
            var temp = _model.get(index)._count;
            if (mouse.button == Qt.RightButton)
            {
                if (temp > 0) _model.setProperty(index, '_count', temp-1);
            }
            else
                if (temp < 4) _model.setProperty(index, '_count', _model.get(index)._count+1);
            if (do_check_start_button) start.enabled = check();
        }
    }

    ListModel {
        id: _model
        
        Component.onCompleted: {
            generate();
        }
    }

    function generate() {
        for (var i = 0; i < 16; i++) _model.append({'_color': 'white', '_count': 0});
    }
}