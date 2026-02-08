import Toybox.WatchUi;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Time;

class checkPageView extends WatchUi.View {
    var checklistItems as Array<String>;
    var checkedStates as Array<Boolean>;
    var scrollOffset as Number;
    var itemsPerScreen as Number;
    var screenWidth as Number;
    var screenHeight as Number;
    
    function initialize() {
        View.initialize();
        
        checklistItems = [
            "NMSK",
            "Pain",
            "Urogential",
            "Anxiety",
            "Depression",
            "Cardiac dysautonomia",
            "Gastrointestinal",
            "Fatigue"
        ];
        
        // Initialize all as unchecked
        checkedStates = new Array<Boolean>[checklistItems.size()];
        for (var i = 0; i < checkedStates.size(); i++) {
            checkedStates[i] = false;
        }
        
        scrollOffset = 0;
        itemsPerScreen = 4;
        screenWidth = 360;
        screenHeight = 360;
    }
    
    function onUpdate(dc as Dc) as Void {
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();
        
        screenWidth = dc.getWidth();
        screenHeight = dc.getHeight();
        
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(
            screenWidth / 2,
            30,
            Graphics.FONT_XTINY,
            "Check all that apply:",
            Graphics.TEXT_JUSTIFY_CENTER
        );
        
        var startY = 80;
        var itemHeight = 45;
        var checkboxSize = 24;
        
        // Calculation
        var startIdx = scrollOffset;
        var endIdx = startIdx + itemsPerScreen;
        if (endIdx > checklistItems.size()) {
            endIdx = checklistItems.size();
        }
        
        for (var i = startIdx; i < endIdx; i++) {
            var yPos = startY + (i - startIdx) * itemHeight;
            
            var checkboxX = 37;
            var checkboxY = yPos;
            
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            dc.drawRectangle(checkboxX, checkboxY, checkboxSize, checkboxSize);
            
            // Fill checkbox if checked
            if (checkedStates[i]) {
                dc.setColor(Graphics.COLOR_GREEN, Graphics.COLOR_TRANSPARENT);
                dc.fillRectangle(checkboxX + 2, checkboxY + 2, checkboxSize - 4, checkboxSize - 4);
            }
            
            // Text labels
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            dc.drawText(
                checkboxX + checkboxSize + 15,
                yPos + checkboxSize/2,
                Graphics.FONT_SMALL,
                checklistItems[i],
                Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER
            );
        }

        var arrowX = screenWidth / 2;
        var arrowY = (screenHeight * 70) / 100;

        if (scrollOffset < checklistItems.size() - itemsPerScreen) {
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(
            arrowX,
            arrowY,
            Graphics.FONT_MEDIUM,
            "v",
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
        );
    }
        
        // DONE button
        var buttonWidth = 160;
        var buttonHeight = 70;
        var buttonX = screenWidth / 2;
        var buttonY = (screenHeight * 88) / 100;
        
        dc.setColor(Graphics.COLOR_GREEN, Graphics.COLOR_TRANSPARENT);
        dc.fillRoundedRectangle(
            buttonX - buttonWidth/2,
            buttonY - buttonHeight/2,
            buttonWidth,
            buttonHeight,
            10
        );
        
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(
            buttonX,
            buttonY,
            Graphics.FONT_MEDIUM,
            "DONE",
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
        );
    }
    
    // Based y coordinate for what was tapped
    function getItemAtPosition(y as Number) as Number {
        var startY = 80;
        var itemHeight = 45;
        
        // Calculate which visible item was tapped
        var relativeY = y - startY;
        if (relativeY < 0) {
            return -1; // Above the list
        }
        
        var itemIndex = relativeY / itemHeight;
        var actualIndex = scrollOffset + itemIndex;
        
        // check bounds
        if (actualIndex >= 0 && actualIndex < checklistItems.size() && itemIndex < itemsPerScreen) {
            return actualIndex;
        }
        
        return -1; 
    }
    
    // Check if DONE button was tapped
    function isDoneTapped(x as Number, y as Number) as Boolean {
        var buttonWidth = 140;
        var buttonHeight = 50;
        var buttonX = screenWidth / 2;
        var buttonY = (screenHeight * 88) / 100;
        
        return (x >= buttonX - buttonWidth/2 && 
                x <= buttonX + buttonWidth/2 &&
                y >= buttonY - buttonHeight/2 && 
                y <= buttonY + buttonHeight/2);
    }
    
    function scrollUp() as Void {
        if (scrollOffset > 0) {
            scrollOffset--;
            WatchUi.requestUpdate();
        }
    }
    
    function scrollDown() as Void {
        if (scrollOffset < checklistItems.size() - itemsPerScreen) {
            scrollOffset++;
            WatchUi.requestUpdate();
        }
    }
    
    function toggleItem(index as Number) as Void {
        if (index >= 0 && index < checkedStates.size()) {
            checkedStates[index] = !checkedStates[index];
            WatchUi.requestUpdate();
        }
    }
    
    function getCheckedItems() as Array<String> {
        var checked = [];
        for (var i = 0; i < checklistItems.size(); i++) {
            if (checkedStates[i]) {
                checked.add(checklistItems[i]);
            }
        }
        return checked;
    }
    
}

class checkPageDelegate extends WatchUi.BehaviorDelegate {
    private var view as checkPageView;
    
    function initialize(v as checkPageView) {
        BehaviorDelegate.initialize();
        view = v;
    }
    
    function onTap(clickEvent as ClickEvent) as Lang.Boolean {
        var coords = clickEvent.getCoordinates();
        var x = coords[0];
        var y = coords[1];
        
        // Check if tap is on DONE button
        if (view.isDoneTapped(x, y)) {
            var checkedItems = view.getCheckedItems();
            System.println("Checked items: " + checkedItems);
            
            // Pass the checked symptoms to questionPageView
            var questionView = new questionPageView(checkedItems);
            WatchUi.pushView(questionView, new QuestionPageDelegate(questionView), WatchUi.SLIDE_UP);
            return true;
        }
        
        // Check if tap is on any checklist item
        var itemIndex = view.getItemAtPosition(y);
        if (itemIndex >= 0) {
            view.toggleItem(itemIndex);
            return true;
        }
        
        return false;
    }
    
    function onPreviousPage() as Lang.Boolean {
        view.scrollUp();
        return true;
    }
    
    function onNextPage() as Lang.Boolean {
        view.scrollDown();
        return true;
    }
    
    function onBack() as Lang.Boolean {
        WatchUi.popView(WatchUi.SLIDE_DOWN);
        return true;
    }
}