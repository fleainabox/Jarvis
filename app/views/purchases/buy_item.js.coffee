$("#credits").html "<div class=\"lead\" id=\"credits\"><%= @credits %> credits</div>"
$("#itemCount-<%= @item.id %>").html "<div class=\"badge badge-inverse\"><%= @purchases %></div>"