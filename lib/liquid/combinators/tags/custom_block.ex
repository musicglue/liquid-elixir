defmodule Liquid.Combinators.Tags.CustomBlock do
  import NimbleParsec
  alias Liquid.Combinators.Tags.CustomTag

  def end_name do
    valid_end_name()
    |> unwrap_and_tag(:custom_name)
  end

  def opener_custom_tag do
    parsec(:start_tag)
    |> concat(end_name())
    |> optional(markup())
    |> parsec(:end_tag)
  end

  def closer_custom_tag do
    parsec(:start_tag)
    |> concat(end_name())
    |> parsec(:end_tag)
  end

  def block do
    opener_custom_tag()
    |> optional(parsec(:__parse__) |> tag(:body))
    |> concat(closer_custom_tag())
    |> traverse({Liquid.Combinators.Tags.CustomBlock, :check_close_tag, []})
    |> tag(:custom_block)
  end

  def check_close_tag(_rest, args, context, _line, _offset) do
    tags_name = Keyword.get_values(args, :custom_name)
    [opened_name, closed_name] = tags_name

    case opened_name == "end" <> closed_name do
      true -> {fix_parse(args), context}
      false -> {:error, "#{opened_name} can be closed by  #{closed_name}"}
    end
  end

  defp valid_markup() do
    repeat_until(utf8_char([]), [string("{%"), string("%}"), string("{{"), string("}}")])
  end

  defp valid_end_name() do
    CustomTag.string_name()
    |> traverse({Liquid.Combinators.Tags.CustomBlock, :check_string_closed, []})
  end

  def check_string_closed(_rest, args, context, _line, _offset) do
    case liquid_tags_without_customs?(args) do
      true -> {:error, "Invalid tag name"}
      false -> {args, context}
    end
  end

  defp markup do
    empty()
    |> parsec(:ignore_whitespaces)
    |> concat(valid_markup())
    |> reduce({List, :to_string, []})
    |> unwrap_and_tag(:custom_markup)
  end

  defp fix_parse(
         custom_name: _endname,
         body: body,
         custom_markup: markup,
         custom_name: name
       ),
       do: [body: body, custom_markup: markup, custom_name: name]

  defp fix_parse(custom_name: _endname, custom_markup: markup, custom_name: name),
    do: [custom_markup: markup, custom_name: name]

  defp liquid_tags_without_customs?([string])
       when string in [
              "case",
              "endcase",
              "assign",
              "decrement",
              "increment",
              "when",
              "if",
              "endif",
              "unless",
              "endunless",
              "capture",
              "endcapture",
              "raw",
              "endraw",
              "for",
              "endfor",
              "break",
              "continue",
              "ifchanged",
              "endifchanged",
              "else",
              "comment",
              "endcomment",
              "tablerow",
              "endtablerow",
              "elsif",
              ""
            ],
       do: true

  defp liquid_tags_without_customs?([_]), do: false
end
