#!/bin/bash

BILL_FILE="bill.txt"
TOTAL=0
DISCOUNT=0
TAX=0
ITEM_NAMES=()
ITEM_QTYS=()
ITEM_PRICES=()
ITEM_TOTALS=()

show_banner() {
    clear
    cols=$(tput cols)
    rows=$(tput lines)
    banner_text="Billing Management System"

    banner_output=$(figlet -w "$cols" -f big "$banner_text")

    banner_lines=$(echo "$banner_output" | wc -l)

    top_padding=$(( (rows - banner_lines - 2) / 2 ))

    for ((i = 0; i < top_padding; i++)); do
        echo
    done

    while IFS= read -r line; do
        printf "%*s\n" $(( (${#line} + cols) / 2 )) "$line"
    done <<< "$banner_output"

    welcome_msg="Welcome to the Billing Management System"
    press_msg="Press any key to continue..."

    printf "\n%*s\n" $(( (${#welcome_msg} + cols) / 2 )) "$welcome_msg"
    printf "%*s\n" $(( (${#press_msg} + cols) / 2 )) "$press_msg"

    read -n 1 -s
}


show_menu() {
    choice=$(dialog --clear --backtitle "Billing System" \
        --title "⭐ Billing System Menu ⭐" \
        --menu "Choose an option:" 20 60 12 \
        1 "Add Item" \
        2 "View Bill" \
        3 "Remove Item" \
        4 "Clear Bill" \
        5 "Apply Discount/Tax" \
        6 "Save & Exit" \
        7 "Search Item" \
        8 "View Total Quantity" \
        9 "Edit Item" \
        10 "Export as CSV" \
        3>&1 1>&2 2>&3)

    clear
    case $choice in
        1) add_item ;;
        2) view_bill ;;
        3) remove_item ;;
        4) clear_bill ;;
        5) apply_discount_tax ;;
        6) save_and_exit ;;
        7) search_item ;;
        8) view_total_quantity ;;
        9) edit_item ;;
        10) export_csv ;;
        *) dialog --msgbox "Invalid choice. Try again." 6 40 ;;
    esac
}

add_item() {
    name=$(dialog --inputbox "📦 Enter item name:" 8 40 3>&1 1>&2 2>&3)
    qty=$(dialog --inputbox "🔢 Enter quantity:" 8 40 3>&1 1>&2 2>&3)
    price=$(dialog --inputbox "💰 Enter price per item:" 8 40 3>&1 1>&2 2>&3)

    total_price=$(echo "$qty * $price" | bc)
    ITEM_NAMES+=("$name")
    ITEM_QTYS+=("$qty")
    ITEM_PRICES+=("$price")
    ITEM_TOTALS+=("$total_price")
    TOTAL=$(echo "$TOTAL + $total_price" | bc)

    dialog --msgbox "✅ Item added successfully!" 6 40
}

view_bill() {
    if [ ${#ITEM_NAMES[@]} -eq 0 ]; then
        dialog --msgbox "📝 Bill is empty." 6 30
        return
    fi

    output="Item       Qty   Price   Total\n--------------------------------\n"
    for i in "${!ITEM_NAMES[@]}"; do
        output+="${ITEM_NAMES[$i]}     ${ITEM_QTYS[$i]}     ₹${ITEM_PRICES[$i]}     ₹${ITEM_TOTALS[$i]}\n"
    done

    output+="--------------------------------\n"
    output+="Subtotal: ₹$TOTAL\n"

    if (( DISCOUNT > 0 )); then
        discount_amount=$(echo "$TOTAL * $DISCOUNT / 100" | bc)
        output+="Discount: $DISCOUNT% (-₹$discount_amount)\n"
    fi
    if (( TAX > 0 )); then
        tax_amount=$(echo "$TOTAL * $TAX / 100" | bc)
        output+="Tax: $TAX% (+₹$tax_amount)\n"
    fi

    final_total=$(echo "$TOTAL - ($TOTAL * $DISCOUNT / 100) + ($TOTAL * $TAX / 100)" | bc)
    output+="Total Payable: ₹$final_total"

    dialog --title "🧾 Current Bill" --msgbox "$output" 20 60
}

remove_item() {
    remove_name=$(dialog --inputbox "❌ Enter item name to remove:" 8 40 3>&1 1>&2 2>&3)
    found=false

    for i in "${!ITEM_NAMES[@]}"; do
        if [[ "${ITEM_NAMES[$i]}" == "$remove_name" ]]; then
            TOTAL=$(echo "$TOTAL - ${ITEM_TOTALS[$i]}" | bc)
            unset 'ITEM_NAMES[i]'
            unset 'ITEM_QTYS[i]'
            unset 'ITEM_PRICES[i]'
            unset 'ITEM_TOTALS[i]'
            ITEM_NAMES=("${ITEM_NAMES[@]}")
            ITEM_QTYS=("${ITEM_QTYS[@]}")
            ITEM_PRICES=("${ITEM_PRICES[@]}")
            ITEM_TOTALS=("${ITEM_TOTALS[@]}")
            dialog --msgbox "🗑 '$remove_name' removed." 6 40
            found=true
            break
        fi
    done
    if ! $found; then
        dialog --msgbox "⚠ Item not found." 6 30
    fi
}

clear_bill() {
    ITEM_NAMES=()
    ITEM_QTYS=()
    ITEM_PRICES=()
    ITEM_TOTALS=()
    TOTAL=0
    DISCOUNT=0
    TAX=0
    dialog --msgbox "🧹 Bill cleared!" 6 30
}

apply_discount_tax() {
    d=$(dialog --inputbox "🔻 Enter discount % (0 if none):" 8 40 3>&1 1>&2 2>&3)
    t=$(dialog --inputbox "➕ Enter tax % (0 if none):" 8 40 3>&1 1>&2 2>&3)

    if [[ "$d" =~ ^[0-9]+$ ]] && [[ "$t" =~ ^[0-9]+$ ]]; then
        DISCOUNT=$d
        TAX=$t
        dialog --msgbox "✅ Discount & Tax applied." 6 40
    else
        dialog --msgbox "❌ Invalid input. Must be numbers." 6 40
    fi
}

save_and_exit() {
    > "$BILL_FILE"
    {
        echo ""
        echo "               FINAL BILL              "
        echo "         Date: $(date '+%d-%m-%Y %H:%M:%S')"
        echo ""
        printf "%-12s %-5s %-6s %-8s\n" "Item" "Qty" "Price" "Total"
        echo "----------------------------------------"
        for i in "${!ITEM_NAMES[@]}"; do
            printf "%-12s %-5s %-6s ₹%-8s\n" "${ITEM_NAMES[$i]}" "${ITEM_QTYS[$i]}" "${ITEM_PRICES[$i]}" "${ITEM_TOTALS[$i]}"
        done
        echo "----------------------------------------"
        echo "Subtotal: ₹$TOTAL"
        if (( DISCOUNT > 0 )); then
            discount_amount=$(echo "$TOTAL * $DISCOUNT / 100" | bc)
            echo "Discount ($DISCOUNT%): -₹$discount_amount"
        fi
        if (( TAX > 0 )); then
            tax_amount=$(echo "$TOTAL * $TAX / 100" | bc)
            echo "Tax ($TAX%): +₹$tax_amount"
        fi
        final_total=$(echo "$TOTAL - ($TOTAL * $DISCOUNT / 100) + ($TOTAL * $TAX / 100)" | bc)
        echo "Total Payable: ₹$final_total"
        echo ""
    } >> "$BILL_FILE"

    dialog --msgbox "💾 Bill saved to '$BILL_FILE'.\nThank you!" 7 50
    clear
    exit 0
}

search_item() {
    search_name=$(dialog --inputbox "🔍 Enter item name to search:" 8 40 3>&1 1>&2 2>&3)
    found=false
    for i in "${!ITEM_NAMES[@]}"; do
        if [[ "${ITEM_NAMES[$i]}" == "$search_name" ]]; then
            dialog --msgbox "✅ Found: ${ITEM_NAMES[$i]}\nQty: ${ITEM_QTYS[$i]}\nPrice: ₹${ITEM_PRICES[$i]}\nTotal: ₹${ITEM_TOTALS[$i]}" 10 50
            found=true
            break
        fi
    done
    if ! $found; then
        dialog --msgbox "❌ '$search_name' not found in bill." 6 40
    fi
}

view_total_quantity() {
    total_qty=0
    for qty in "${ITEM_QTYS[@]}"; do
        total_qty=$((total_qty + qty))
    done
    dialog --msgbox "🛒 Total Quantity of Items: $total_qty" 6 40
}

edit_item() {
    edit_name=$(dialog --inputbox "✏ Enter item name to edit:" 8 40 3>&1 1>&2 2>&3)
    found=false
    for i in "${!ITEM_NAMES[@]}"; do
        if [[ "${ITEM_NAMES[$i]}" == "$edit_name" ]]; then
            new_name=$(dialog --inputbox "📦 New item name:" 8 40 "${ITEM_NAMES[$i]}" 3>&1 1>&2 2>&3)
            new_qty=$(dialog --inputbox "🔢 New quantity:" 8 40 "${ITEM_QTYS[$i]}" 3>&1 1>&2 2>&3)
            new_price=$(dialog --inputbox "💰 New price per item:" 8 40 "${ITEM_PRICES[$i]}" 3>&1 1>&2 2>&3)

            old_total=${ITEM_TOTALS[$i]}
            TOTAL=$(echo "$TOTAL - $old_total" | bc)

            new_total=$(echo "$new_qty * $new_price" | bc)
            TOTAL=$(echo "$TOTAL + $new_total" | bc)

            ITEM_NAMES[$i]="$new_name"
            ITEM_QTYS[$i]="$new_qty"
            ITEM_PRICES[$i]="$new_price"
            ITEM_TOTALS[$i]="$new_total"

            dialog --msgbox "✅ Item updated successfully!" 6 40
            found=true
            break
        fi
    done

    if ! $found; then
        dialog --msgbox "❌ '$edit_name' not found." 6 40
    fi
}

export_csv() {
    csv_file="bill.csv"
    {
        echo "Item,Quantity,Price,Total"
        for i in "${!ITEM_NAMES[@]}"; do
            echo "${ITEM_NAMES[$i]},${ITEM_QTYS[$i]},${ITEM_PRICES[$i]},${ITEM_TOTALS[$i]}"
        done
        echo "Subtotal,,$TOTAL"
        if (( DISCOUNT > 0 )); then
            discount_amount=$(echo "$TOTAL * $DISCOUNT / 100" | bc)
            echo "Discount (${DISCOUNT}%),,-$discount_amount"
        fi
        if (( TAX > 0 )); then
            tax_amount=$(echo "$TOTAL * $TAX / 100" | bc)
            echo "Tax (${TAX}%),,$tax_amount"
        fi
        final_total=$(echo "$TOTAL - ($TOTAL * $DISCOUNT / 100) + ($TOTAL * $TAX / 100)" | bc)
        echo "Total Payable,,,$final_total"
    } > "$csv_file"

    dialog --msgbox "📤 Bill exported to $csv_file" 6 50
}

# Main Execution
show_banner
dialog --title "👋 Welcome" --msgbox "Welcome to the Billing Management System!\n\nPress OK to continue." 10 50

while true; do
    show_menu
done