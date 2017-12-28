defmodule WechatPay.XML.Parser do
  @moduledoc """
  Module to convert a XML string to map
  """
  require WechatPay.XML.Record

  alias WechatPay.XML.Record, as: XMLRecord
  alias WechatPay.Error

  @doc """
  Convert the response XML string to map

  ## Example

  ```elixir
  iex> WechatPay.XML.Parser.parse("<xml><foo><![CDATA[bar]]></foo></xml>", "xml")
  ...> {:ok, %{foo: "bar"}}

  iex> WechatPay.XML.Parser.parse("<root><foo><![CDATA[bar]]></foo></root>", "root")
  ...> {:ok, %{foo: "bar"}}
  ```
  """
  @spec parse(String.t, String.t) :: {:ok, map} | {:error, Error.t}
  def parse(xml_string, root_element \\ "xml") when is_binary(xml_string) do
    try do
      {doc, _} =
        xml_string
        |> :binary.bin_to_list()
        |> :xmerl_scan.string()

      parsed_xml = extract_doc(doc, root_element)

      {:ok, parsed_xml}
    catch
      :exit, _ ->
        {:error, %Error{reason: "Malformed XML, requires root element: #{root_element}", type: :malformed_xml}}
    end
  end

  defp extract_doc(doc, root) do
    "/#{root}/child::*"
    |> String.to_charlist()
    |> :xmerl_xpath.string(doc)
    |> Enum.map(&extract_element/1)
    |> Enum.into(%{})
  end

  defp extract_element(element) do
    name = XMLRecord.xml_element(element, :name)

    [content] = XMLRecord.xml_element(element, :content)

    value =
      content
      |> XMLRecord.xml_text(:value)
      |> String.Chars.to_string

    {name, value}
  end
end
