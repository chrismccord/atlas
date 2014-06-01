defmodule Atlas.Relationships do

  defrecord BelongsTo, name: nil, model: nil, foreign_key: nil
  defrecord HasMany, name: nil, model: nil, foreign_key: nil

  defmacro __using__(_options) do
    quote do
      Module.register_attribute __MODULE__, :belongs_to, accumulate: true, persist: false
      Module.register_attribute __MODULE__, :has_many, accumulate: true, persist: false
      import unquote(__MODULE__)

      @before_compile unquote(__MODULE__)
    end
  end

  defmacro __before_compile__(_env) do
    quote unquote: false do
      def __atlas__(:belongs_to), do: @belongs_to || []
      def __atlas__(:has_many), do: @has_many || []

      def find_relationship(identifier) do
        find_belongs_to(identifier) || find_has_many(identifier)
      end

      def find_belongs_to(identifier) do
        Enum.find @belongs_to, fn relation ->
          relation.name == identifier || relation.model == identifier
        end
      end

      def find_has_many(identifier) do
        Enum.find @has_many, fn relation ->
          relation.name == identifier || relation.model == identifier
        end
      end

      Enum.each @belongs_to, fn BelongsTo[name: name, model: model, foreign_key: fkey] ->
        @doc """
        Return query expression for `belongs_to :#{name}` relationship to find
        #{model} by #{__MODULE__}'s primary key
        """
        def unquote(name)(record) do
          pkey = apply(unquote(model), :primary_key, [])
          fkey_value = Map.get(record, unquote(fkey))
          apply(unquote(model), :where, [[{pkey, fkey_value}]])
        end
      end

      Enum.each @has_many, fn HasMany[name: name, model: model, foreign_key: fkey] ->
        @doc """
        Return query expression for `has_many :#{name}` relationship to find all
        #{model}'s by #{__MODULE__}'s' primary key
        """
        def unquote(name)(record) do
          apply(unquote(model), :where, [[{unquote(fkey), primary_key_value(record)}]])
        end
      end
    end
  end


  defmacro belongs_to(name, options \\ []) do
    quote do
      @belongs_to BelongsTo.new(name: unquote(name),
                                model: unquote(options[:model]),
                                foreign_key: unquote(options[:foreign_key]))
    end
  end

  defmacro has_many(name, options \\ []) do
    quote do
      @has_many HasMany.new(name: unquote(name),
                            model: unquote(options[:model]),
                            foreign_key: unquote(options[:foreign_key]))
    end
  end
end
