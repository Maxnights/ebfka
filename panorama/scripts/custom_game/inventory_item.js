"use strict";

var m_Item = -1;
var m_ItemSlot = -1;
var m_QueryUnit = -1;

function UpdateItem()
{
	var itemName = Abilities.GetAbilityName( m_Item );
	var hotkey = Abilities.GetKeybind( m_Item, m_QueryUnit );
	var isPassive = Abilities.IsPassive( m_Item );
	var chargeCount = 0;
	var hasCharges = false;
	var altChargeCount = 0;
	var hasAltCharges = false;
	
	if ( Items.ShowSecondaryCharges( m_Item ) )
	{
		hasCharges = true;
		hasAltCharges = true;
		if ( Abilities.GetToggleState( m_Item ) )
		{
			chargeCount = Items.GetCurrentCharges( m_Item );
			altChargeCount = Items.GetSecondaryCharges( m_Item );
		}
		else
		{
			altChargeCount = Items.GetCurrentCharges( m_Item );
			chargeCount = Items.GetSecondaryCharges( m_Item );
		}
	}
	else if ( Items.ShouldDisplayCharges( m_Item ) )
	{
		hasCharges = true;
		chargeCount = Items.GetCurrentCharges( m_Item );
	}

	$.GetContextPanel().SetHasClass( "no_item", (m_Item == -1) );
	$.GetContextPanel().SetHasClass( "show_charges", hasCharges );
	$.GetContextPanel().SetHasClass( "show_alt_charges", hasAltCharges );
	$.GetContextPanel().SetHasClass( "is_passive", isPassive );
	
	$( "#HotkeyText" ).text = hotkey;
	$( "#ItemImage" ).itemname = itemName;
	$( "#ItemImage" ).contextEntityIndex = m_Item;
	$( "#ChargeCount" ).text = chargeCount;
	$( "#AltChargeCount" ).text = altChargeCount;
	
	if ( m_Item == -1 || Abilities.IsCooldownReady( m_Item ) )
	{
		$.GetContextPanel().SetHasClass( "cooldown_ready", true );
		$.GetContextPanel().SetHasClass( "in_cooldown", false );
	}
	else
	{
		$.GetContextPanel().SetHasClass( "cooldown_ready", false );
		$.GetContextPanel().SetHasClass( "in_cooldown", true );
		var cooldownLength = Abilities.GetCooldownLength( m_Item );
		var cooldownRemaining = Abilities.GetCooldownTimeRemaining( m_Item );
		var cooldownPercent = Math.ceil( 100 * cooldownRemaining / cooldownLength );
		$( "#CooldownTimer" ).text = Math.ceil( cooldownRemaining );
		$( "#CooldownOverlay" ).style.width = cooldownPercent+"%";
	}
	
	$.Schedule( 0.1, UpdateItem );
}

function ItemShowTooltip()
{
	if ( m_Item == -1 ) return;
	var itemName = Abilities.GetAbilityName( m_Item );
	$.DispatchEvent( "DOTAShowAbilityTooltipForEntityIndex", $.GetContextPanel(), itemName, m_QueryUnit );
}

function ItemHideTooltip() { $.DispatchEvent( "DOTAHideAbilityTooltip", $.GetContextPanel() ); }
function ActivateItem() { if ( m_Item == -1 ) return; Abilities.ExecuteAbility( m_Item, m_QueryUnit, false ); }
function DoubleClickItem() { ActivateItem(); }

var DOTA_ITEM_STASH_MIN = 6;
function IsInStash() { return ( m_ItemSlot >= DOTA_ITEM_STASH_MIN ); }

function RightClickItem()
{
	ItemHideTooltip();

	// ИСПРАВЛЕНИЕ: Используем == вместо ===
	if (m_ItemSlot == 16 && m_Item != -1) {
		GameEvents.SendCustomGameEventToServer("take_out_neutral_item", { item_entindex: m_Item });
		return; 
	}

	var bSlotInStash = IsInStash();
	var bControllable = Entities.IsControllableByPlayer( m_QueryUnit, Game.GetLocalPlayerID() );
	var bSellable = Items.IsSellable( m_Item ) && Items.CanBeSoldByLocalPlayer( m_Item );
	var bDisassemble = Items.IsDisassemblable( m_Item ) && bControllable && !bSlotInStash;
	var bAlertable = Items.IsAlertableItem( m_Item );
	var bShowInShop = Items.IsPurchasable( m_Item );
	var bDropFromStash = bControllable;

	if ( !bSellable && !bDisassemble && !bShowInShop && !bDropFromStash && !bAlertable && !bMoveToStash ) return;

	var contextMenu = $.CreatePanel( "DOTAContextMenuScript", $.GetContextPanel(), "" );
	contextMenu.AddClass( "ContextMenu_NoArrow" );
	contextMenu.AddClass( "ContextMenu_NoBorder" );
	contextMenu.GetContentsPanel().Data().Item = m_Item;
	contextMenu.GetContentsPanel().SetHasClass( "bSellable", bSellable );
	contextMenu.GetContentsPanel().SetHasClass( "bDisassemble", bDisassemble );
	contextMenu.GetContentsPanel().SetHasClass( "bShowInShop", bShowInShop );
	contextMenu.GetContentsPanel().SetHasClass( "bDropFromStash", bDropFromStash );
	contextMenu.GetContentsPanel().SetHasClass( "bAlertable", bAlertable );
	contextMenu.GetContentsPanel().SetHasClass( "bMoveToStash", false );
	contextMenu.GetContentsPanel().BLoadLayout( "file://{resources}/layout/custom_game/inventory_context_menu.xml", false, false );
}

function OnDragEnter( a, draggedPanel )
{
	var draggedItem = draggedPanel.Data().m_DragItem;
	if ( draggedItem === null || draggedItem == m_Item ) return true;
	$.GetContextPanel().AddClass( "potential_drop_target" );
	return true;
}

function OnDragStart( panelId, dragCallbacks )
{
	if ( m_Item == -1 ) return true;

	var itemName = Abilities.GetAbilityName( m_Item );
	ItemHideTooltip();

	var displayPanel = $.CreatePanel( "DOTAItemImage", $.GetContextPanel(), "dragImage" );
	displayPanel.itemname = itemName;
	displayPanel.contextEntityIndex = m_Item;
	displayPanel.Data().m_DragItem = m_Item;
	displayPanel.Data().m_DragItemSlot = m_ItemSlot; // Запоминаем слот!
	displayPanel.Data().m_DragCompleted = false; 

	dragCallbacks.displayPanel = displayPanel;
	dragCallbacks.offsetX = 0;
	dragCallbacks.offsetY = 0;
	
	$.GetContextPanel().AddClass( "dragging_from" );
	return true;
}

function OnDragDrop( panelId, draggedPanel )
{
	var draggedItem = draggedPanel.Data().m_DragItem;
	if ( draggedItem === null ) return true;
	draggedPanel.Data().m_DragCompleted = true;
	if ( draggedItem == m_Item ) return true;

	var sourceSlot = draggedPanel.Data().m_DragItemSlot;
	
	// ИСПРАВЛЕНИЕ: Используем == вместо ===
	if (m_ItemSlot == 16 || sourceSlot == 16) {
		GameEvents.SendCustomGameEventToServer("force_swap_item", {
			source_slot: sourceSlot,
			target_slot: m_ItemSlot
		});
		return true; 
	}

	var moveItemOrder = {
		OrderType: dotaunitorder_t.DOTA_UNIT_ORDER_MOVE_ITEM,
		TargetIndex: m_ItemSlot,
		AbilityIndex: draggedItem
	};
	Game.PrepareUnitOrders( moveItemOrder );
	return true;
}

function OnDragLeave( panelId, draggedPanel )
{
	var draggedItem = draggedPanel.Data().m_DragItem;
	if ( draggedItem === null || draggedItem == m_Item ) return false;
	$.GetContextPanel().RemoveClass( "potential_drop_target" );
	return true;
}

function OnDragEnd( panelId, draggedPanel )
{
	// ИСПРАВЛЕНИЕ: Любой бросок на землю идет через наш сервер!
	if ( !draggedPanel.Data().m_DragCompleted )
	{
		GameEvents.SendCustomGameEventToServer("force_drop_item", {
			item_entindex: m_Item
		});
	}

	draggedPanel.DeleteAsync( 0 );
	$.GetContextPanel().RemoveClass( "dragging_from" );
	return true;
}

function SetItemSlot( itemSlot ) { m_ItemSlot = itemSlot; }
function SetItem( queryUnit, iItem ) { m_Item = iItem; m_QueryUnit = queryUnit; }

(function()
{
	$.GetContextPanel().Data().SetItem = SetItem;
	$.GetContextPanel().Data().SetItemSlot = SetItemSlot;

	$.RegisterEventHandler( 'DragEnter', $.GetContextPanel(), OnDragEnter );
	$.RegisterEventHandler( 'DragDrop', $.GetContextPanel(), OnDragDrop );
	$.RegisterEventHandler( 'DragLeave', $.GetContextPanel(), OnDragLeave );
	$.RegisterEventHandler( 'DragStart', $.GetContextPanel(), OnDragStart );
	$.RegisterEventHandler( 'DragEnd', $.GetContextPanel(), OnDragEnd );

	UpdateItem(); 
})();